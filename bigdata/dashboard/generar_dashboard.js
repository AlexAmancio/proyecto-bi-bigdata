// Genera bigdata/dashboard/tunki_lodge.lvdash.json (dashboard de Databricks AI/BI) a partir de las tablas Gold.
// Uso: node generar_dashboard.js
const fs = require('fs');
const path = require('path');

const G = 'workspace.tunki_gold';

const datasets = [];
const ds = (name, displayName, sql) => { datasets.push({ name, displayName, queryLines: [sql] }); return name; };

// ---------------------------------------------------------------- datasets
ds('kpi_2026', 'KPIs 2026 (mismo periodo)',
  `SELECT reservas, ROUND(var_interanual_reservas * 100, 1) AS var_reservas_pct, ROUND(pct_cancelacion * 100, 1) AS cancelacion_pct, ROUND(pct_no_show * 100, 1) AS no_show_pct, ROUND(ingreso_por_estadia, 0) AS ingreso_por_estadia FROM ${G}.kpi_anual WHERE origen = 'sistema' AND \`año\` = 2026`);
ds('mensual', 'KPIs mensuales',
  `SELECT CAST(\`año\` AS STRING) AS \`año\`, mes, reservas, ROUND(pct_cancelacion * 100, 1) AS cancelacion_pct, ROUND(pct_no_llegada * 100, 1) AS no_llegada_pct FROM ${G}.kpi_mensual WHERE origen = 'sistema'`);
const segmento = (nombre, dim) => ds(nombre, `No-llegada por ${dim.toLowerCase()}`,
  `SELECT segmento, SUM(reservas) AS reservas, ROUND(100 * SUM(canceladas + no_show) / SUM(reservas), 1) AS no_llegada_pct FROM ${G}.no_llegada_segmento WHERE origen = 'sistema' AND dimension = '${dim}' GROUP BY segmento`);
segmento('seg_zona', 'Zona de origen');
segmento('seg_pago', 'Método de pago');
ds('escalabilidad', 'EXP-BD-01 escalabilidad',
  `SELECT CASE WHEN escenario LIKE 'Ingesta%' THEN 'Ingesta' ELSE 'Limpieza + KPIs' END AS etapa, filas, ROUND(AVG(segundos), 2) AS segundos FROM ${G}.experimentos WHERE experimento = 'EXP-BD-01' AND fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM ${G}.experimentos) GROUP BY 1, 2`);

// ---------------------------------------------------------------- widgets
let n = 0;
const id = p => `${p}_${++n}`;
const NOMBRES = { segmento: 'Segmento', no_llegada_pct: '% No-llegada', mes: 'Mes', reservas: 'Reservas', cancelacion_pct: '% Cancelación', 'año': 'Año', filas: 'Filas procesadas', segundos: 'Segundos', etapa: 'Etapa', zona: 'Zona', regla: 'Regla', descripcion: 'Problema', registros_afectados: 'Registros', accion: 'Acción', metrica: 'Métrica', power_bi: 'Power BI', databricks: 'Databricks', resultado: 'Resultado', experimento: 'Experimento', escenario: 'Escenario', promedio_s: 'Promedio (s)', desv_s: 'Desv. (s)' };
const nom = c => NOMBRES[c] || c;
const campo = (nombre, expr) => ({ name: nombre, expression: expr || `\`${nombre}\`` });
const consulta = (dataset, fields, disaggregated = true) =>
  [{ name: 'main_query', query: { datasetName: dataset, fields, disaggregated } }];

const texto = (lineas, pos) => ({ widget: { name: id('texto'), multilineTextboxSpec: { lines: lineas } }, position: pos });
const tarjeta = (dataset, col, titulo, pos) => ({
  widget: {
    name: id('tarjeta'),
    queries: consulta(dataset, [campo(col)]),
    spec: { version: 2, widgetType: 'counter', encodings: { value: { fieldName: col, displayName: titulo } }, frame: { showTitle: true, title: titulo } },
  },
  position: pos,
});
const barras = (dataset, x, y, titulo, pos, color) => ({
  widget: {
    name: id('barras'),
    queries: consulta(dataset, [campo(x), campo(y)].concat(color ? [campo(color)] : [])),
    spec: {
      version: 3, widgetType: 'bar',
      encodings: Object.assign({
        x: { fieldName: x, scale: { type: 'categorical' }, displayName: nom(x) },
        y: { fieldName: y, scale: { type: 'quantitative' }, displayName: nom(y) },
      }, color ? { color: { fieldName: color, scale: { type: 'categorical' }, displayName: nom(color) } } : {}),
      frame: { showTitle: true, title: titulo },
    },
  },
  position: pos,
});
const lineas = (dataset, x, y, color, titulo, pos, tipoX = 'categorical') => ({
  widget: {
    name: id('lineas'),
    queries: consulta(dataset, [campo(x), campo(y), campo(color)]),
    spec: {
      version: 3, widgetType: 'line',
      encodings: {
        x: { fieldName: x, scale: { type: tipoX }, displayName: nom(x) },
        y: { fieldName: y, scale: { type: 'quantitative' }, displayName: nom(y) },
        color: { fieldName: color, scale: { type: 'categorical' }, displayName: nom(color) },
      },
      frame: { showTitle: true, title: titulo },
    },
  },
  position: pos,
});
const tabla = (dataset, cols, titulo, pos) => ({
  widget: {
    name: id('tabla'),
    queries: consulta(dataset, cols.map(c => campo(c))),
    spec: { version: 1, widgetType: 'table', encodings: { columns: cols.map(c => ({ fieldName: c, displayName: nom(c) })) }, frame: { showTitle: true, title: titulo } },
  },
  position: pos,
});
const P = (x, y, width, height) => ({ x, y, width, height });

// ---------------------------------------------------------------- páginas
const resumen = [
  texto(['# Tunki Lodge · Reservas y no-llegada de huéspedes', 'Solución Big Data (Databricks, arquitectura Medallion). Tarjetas: enero–octubre de 2026 frente al mismo periodo de 2025. Datos reales (origen = sistema).'], P(0, 0, 6, 2)),
  // 1. KPIs de 2026 (tarjetas)
  tarjeta('kpi_2026', 'reservas', 'Reservas 2026', P(0, 2, 1, 3)),
  tarjeta('kpi_2026', 'var_reservas_pct', 'Var. interanual (%)', P(1, 2, 1, 3)),
  tarjeta('kpi_2026', 'cancelacion_pct', '% Cancelación', P(2, 2, 1, 3)),
  tarjeta('kpi_2026', 'no_show_pct', '% No-show', P(3, 2, 1, 3)),
  tarjeta('kpi_2026', 'ingreso_por_estadia', 'Ingreso por estadía (S/)', P(4, 2, 2, 3)),
  // 2 y 3. Evolución mensual
  lineas('mensual', 'mes', 'reservas', 'año', 'Reservas por mes y año', P(0, 5, 3, 6)),
  lineas('mensual', 'mes', 'cancelacion_pct', 'año', '% de cancelación por mes y año', P(3, 5, 3, 6)),
  // 4 y 5. Factores de no-llegada
  barras('seg_zona', 'segmento', 'no_llegada_pct', '% de no-llegada por zona de origen', P(0, 11, 3, 6)),
  barras('seg_pago', 'segmento', 'no_llegada_pct', '% de no-llegada por método de pago', P(3, 11, 3, 6)),
  // 6. Escalabilidad de la solución Big Data
  lineas('escalabilidad', 'filas', 'segundos', 'etapa', 'Escalabilidad (EXP-BD-01): segundos según filas procesadas, ×1 a ×300', P(0, 17, 6, 6), 'quantitative'),
];

const dashboard = {
  datasets,
  pages: [{ name: 'resumen', displayName: 'Tunki Lodge', layout: resumen }],
};
const destino = path.join(__dirname, 'tunki_lodge.lvdash.json');
fs.writeFileSync(destino, JSON.stringify(dashboard, null, 2), 'utf8');
console.log('Generado', destino, '-', datasets.length, 'datasets,', dashboard.pages.length, 'páginas');
