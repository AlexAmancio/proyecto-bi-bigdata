// Genera bigdata/dashboard/tunki_lodge.lvdash.json (dashboard de Databricks AI/BI) a partir de las tablas Gold.
// Uso: node generar_dashboard.js
const fs = require('fs');
const path = require('path');

const G = 'workspace.tunki_gold';
const S = 'workspace.tunki_silver';
const datasets = [];
const ds = (name, displayName, sql) => { datasets.push({ name, displayName, queryLines: [sql] }); return name; };

// ---------------------------------------------------------------- datasets
// KPIs por año (enero hasta la fecha de corte). El filtro "Año" de la página elige cuál mostrar en las tarjetas.
ds('kpi_anual', 'KPIs por año (mismo periodo)',
  `SELECT CAST(\`año\` AS STRING) AS \`año\`, reservas, ROUND(var_interanual_reservas * 100, 1) AS var_reservas_pct, ROUND(pct_cancelacion * 100, 1) AS cancelacion_pct, ROUND(pct_no_show * 100, 1) AS no_show_pct, ROUND(ingreso_por_estadia, 0) AS ingreso_por_estadia FROM ${G}.kpi_anual WHERE origen = 'sistema'`);
ds('mensual', 'KPIs mensuales',
  `SELECT CAST(\`año\` AS STRING) AS \`año\`, mes, reservas, ROUND(pct_cancelacion * 100, 1) AS cancelacion_pct, ROUND(pct_no_llegada * 100, 1) AS no_llegada_pct FROM ${G}.kpi_mensual WHERE origen = 'sistema'`);
// Una fila por segmento y año: cada gráfico muestra una barra por año y el filtro "Año" elige cuáles ver.
const segmento = (nombre, dim) => ds(nombre, `No-llegada por ${dim.toLowerCase()}`,
  `SELECT CAST(\`año\` AS STRING) AS \`año\`, segmento, reservas, ROUND(pct_no_llegada * 100, 1) AS no_llegada_pct FROM ${G}.no_llegada_segmento WHERE origen = 'sistema' AND dimension = '${dim}'`);
segmento('seg_zona', 'Zona de origen');
segmento('seg_pago', 'Método de pago');
segmento('seg_categoria', 'Categoría');
segmento('seg_tipo', 'Tipo de cliente');
segmento('seg_grupo', 'Tamaño de grupo');
ds('zona_anual', 'No-llegada por zona y año',
  `SELECT CAST(\`año\` AS STRING) AS \`año\`, segmento AS zona, ROUND(pct_no_llegada * 100, 1) AS no_llegada_pct FROM ${G}.no_llegada_segmento WHERE origen = 'sistema' AND dimension = 'Zona de origen'`);
ds('calidad', 'Reglas de calidad (Silver)',
  `SELECT regla, descripcion, tabla, registros_afectados, accion FROM ${S}.calidad WHERE fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM ${S}.calidad) ORDER BY regla`);
ds('validacion', 'Validación con Power BI', `SELECT metrica, power_bi, databricks, resultado FROM ${G}.validacion_bi`);
ds('escalabilidad', 'EXP-BD-01 escalabilidad',
  `SELECT CASE WHEN escenario LIKE 'Ingesta%' THEN 'Ingesta' ELSE 'Limpieza + KPIs' END AS etapa, filas, ROUND(AVG(segundos), 2) AS segundos FROM ${G}.experimentos WHERE experimento = 'EXP-BD-01' AND fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM ${G}.experimentos) GROUP BY 1, 2`);
ds('experimentos', 'Experimentos de configuración',
  `SELECT experimento, escenario, ROUND(AVG(segundos), 3) AS promedio_s, ROUND(STDDEV(segundos), 3) AS desv_s FROM ${G}.experimentos WHERE experimento <> 'EXP-BD-01' AND fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM ${G}.experimentos) GROUP BY 1, 2 ORDER BY 1, 2`);

// ---------------------------------------------------------------- widgets
let n = 0;
const id = p => `${p}_${++n}`;
const NOMBRES = { segmento: 'Segmento', no_llegada_pct: '% No-llegada', mes: 'Mes', reservas: 'Reservas', cancelacion_pct: '% Cancelación', 'año': 'Año', filas: 'Filas procesadas', segundos: 'Segundos', etapa: 'Etapa', zona: 'Zona', regla: 'Regla', descripcion: 'Problema', registros_afectados: 'Registros', accion: 'Acción', metrica: 'Métrica', power_bi: 'Power BI', databricks: 'Databricks', resultado: 'Resultado', experimento: 'Experimento', escenario: 'Escenario', promedio_s: 'Promedio (s)', desv_s: 'Desv. (s)' };
const nom = c => NOMBRES[c] || c;
const campo = (nombre, expr) => ({ name: nombre, expression: expr || `\`${nombre}\`` });
const consulta = (dataset, fields, disaggregated = true) =>
  [{ name: 'main_query', query: { datasetName: dataset, fields, disaggregated } }];

const texto = (lineas, pos) => ({ widget: { name: id('texto'), multilineTextboxSpec: { lines: lineas.map(l => l.replace(/^# /, '## ') + '\n') } }, position: pos });
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
      // barras de cada año una al lado de la otra (no apiladas: son porcentajes)
      mark: color ? { layout: 'group' } : undefined,
      frame: { showTitle: true, title: titulo },
    },
  },
  position: pos,
});
// Filtro (como un segmentador de Power BI) sobre un campo, aplicado a varios datasets de la página.
const filtro = (titulo, campoFiltro, datasetsFiltrados, tipo, pos, valorPorDefecto) => {
  const queries = datasetsFiltrados.map(d => ({
    name: `filtro_${campoFiltro}_${d}`.replace(/[^a-zA-Z0-9_]/g, '_'),
    query: { datasetName: d, fields: [campo(campoFiltro)], disaggregated: false },
  }));
  const spec = {
    version: 2, widgetType: tipo,
    encodings: { fields: queries.map(q => ({ fieldName: campoFiltro, displayName: titulo, queryName: q.name })) },
    frame: { showTitle: true, title: titulo },
  };
  if (valorPorDefecto) spec.selection = { defaultSelection: { values: { dataType: 'STRING', values: [{ value: valorPorDefecto }] } } };
  return { widget: { name: id('filtro'), queries, spec }, position: pos };
};
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
    spec: {
      version: 1, widgetType: 'table',
      encodings: { columns: cols.map((c, i) => columnaTabla(c, i)) },
      invisibleColumns: [], allowHTMLByDefault: false, itemsPerPage: 25, paginationSize: 'default', condensed: true, withRowNumber: false,
      frame: { showTitle: true, title: titulo },
    },
  },
  position: pos,
});
const P = (x, y, width, height) => ({ x, y, width, height });
const NUMERICAS = { registros_afectados: 'integer', power_bi: 'float', databricks: 'float', promedio_s: 'float', desv_s: 'float' };
function columnaTabla(c, i) {
  const tipo = NUMERICAS[c] || 'string';
  return {
    fieldName: c, displayName: nom(c), title: nom(c), type: tipo, displayAs: tipo === 'string' ? 'string' : 'number',
    visible: true, order: 100000 + i, alignContent: tipo === 'string' ? 'left' : 'right', allowSearch: false,
    booleanValues: ['false', 'true'], imageUrlTemplate: '{{ @ }}', imageTitleTemplate: '{{ @ }}', imageWidth: '', imageHeight: '',
    linkUrlTemplate: '{{ @ }}', linkTextTemplate: '{{ @ }}', linkTitleTemplate: '{{ @ }}', linkOpenInNewTab: true,
    allowHTML: false, highlightLinks: false, useMonospaceFont: false, preserveWhitespace: false,
  };
}

// ---------------------------------------------------------------- páginas
const resumen = [
  texto(['# Tunki Lodge · Reservas y no-llegada de huéspedes', 'Solución Big Data (Databricks, arquitectura Medallion). Tarjetas: año elegido en el filtro, de enero a la fecha de corte, frente al mismo periodo del año anterior. Datos reales (origen = sistema).'], P(0, 0, 5, 2)),
  filtro('Año', 'año', ['kpi_anual'], 'filter-single-select', P(5, 0, 1, 2), '2026'),
  tarjeta('kpi_anual', 'reservas', 'Reservas', P(0, 2, 2, 3)),
  tarjeta('kpi_anual', 'var_reservas_pct', 'Var. interanual (%)', P(2, 2, 1, 3)),
  tarjeta('kpi_anual', 'cancelacion_pct', '% Cancelación', P(3, 2, 1, 3)),
  tarjeta('kpi_anual', 'no_show_pct', '% No-show', P(4, 2, 1, 3)),
  tarjeta('kpi_anual', 'ingreso_por_estadia', 'Ingreso por estadía (S/)', P(5, 2, 1, 3)),
  lineas('mensual', 'mes', 'reservas', 'año', 'Reservas por mes y año', P(0, 5, 3, 6)),
  lineas('mensual', 'mes', 'cancelacion_pct', 'año', '% de cancelación por mes y año', P(3, 5, 3, 6)),
];
const factores = [
  texto(['# Factores de no-llegada', '% de no-llegada (cancelación + no-show) por segmento, una barra por año. Use el filtro para elegir los años.'], P(0, 0, 5, 2)),
  filtro('Año', 'año', ['seg_zona', 'seg_pago', 'seg_categoria', 'seg_tipo', 'seg_grupo', 'zona_anual'], 'filter-multi-select', P(5, 0, 1, 2)),
  barras('seg_zona', 'segmento', 'no_llegada_pct', 'Por zona de origen', P(0, 2, 3, 5), 'año'),
  barras('seg_pago', 'segmento', 'no_llegada_pct', 'Por método de pago', P(3, 2, 3, 5), 'año'),
  barras('seg_categoria', 'segmento', 'no_llegada_pct', 'Por categoría de habitación', P(0, 7, 3, 5), 'año'),
  barras('seg_tipo', 'segmento', 'no_llegada_pct', 'Por tipo de cliente', P(3, 7, 3, 5), 'año'),
  barras('seg_grupo', 'segmento', 'no_llegada_pct', 'Por tamaño de grupo', P(0, 12, 3, 5), 'año'),
  barras('zona_anual', 'zona', 'no_llegada_pct', 'Por zona y año', P(3, 12, 3, 5), 'año'),
];
const calidadExp = [
  texto(['# Calidad de datos y experimentos', 'Reglas aplicadas en Silver, validación cruzada con Power BI y resultados de la última ejecución de experimentos.'], P(0, 0, 6, 2)),
  tabla('calidad', ['regla', 'descripcion', 'registros_afectados', 'accion'], 'Reglas de calidad (tunki_silver.calidad)', P(0, 2, 3, 7)),
  tabla('validacion', ['metrica', 'power_bi', 'databricks', 'resultado'], 'Validación: Gold frente a Power BI', P(3, 2, 3, 7)),
  lineas('escalabilidad', 'filas', 'segundos', 'etapa', 'EXP-BD-01 · Segundos según filas procesadas (×1 a ×300)', P(0, 9, 3, 6), 'quantitative'),
  tabla('experimentos', ['experimento', 'escenario', 'promedio_s', 'desv_s'], 'EXP-BD-02 a 06 · Tiempos promedio (s)', P(3, 9, 3, 6)),
];

const dashboard = {
  datasets,
  pages: [
    { name: 'resumen', displayName: 'Resumen', layout: resumen },
    { name: 'factores', displayName: 'Factores de no-llegada', layout: factores },
    { name: 'calidad_experimentos', displayName: 'Calidad y experimentos', layout: calidadExp },
  ],
};
const destino = path.join(__dirname, 'tunki_lodge.lvdash.json');
fs.writeFileSync(destino, JSON.stringify(dashboard, null, 2), 'utf8');
console.log('Generado', destino, '-', datasets.length, 'datasets,', dashboard.pages.length, 'páginas');
