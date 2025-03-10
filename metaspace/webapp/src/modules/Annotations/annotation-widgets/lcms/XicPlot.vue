<template>
  <div
    ref="xicChart"
    style="height: 300px;"
  >
    <el-button
      v-if="showLogIntSwitch"
      class="log-scale-switch"
      type="primary"
      plain
      @click="setLogIntensity(!internalLogIntensity)"
    >
      {{ internalLogIntensity ? 'Log' : 'Linear' }}
    </el-button>
  </div>
</template>

<script>
import * as d3 from 'd3'

function imageToIntensity(intensityImgUrl, maxIntensity) {
  const requestParams = {
    method: 'GET',
    cache: 'force-cache',
  }

  return fetch(intensityImgUrl, requestParams).then(response => {
    if (!response.ok) {
      throw response.statusText
    } else {
      return response.arrayBuffer()
    }
  }).then(buf => {
    const pixelArray = new Uint8Array(buf)
    const result = new Float32Array(pixelArray.length)
    for (let i = 0, pixCount = pixelArray.length; i < pixCount; ++i) {
      result[i] = maxIntensity * pixelArray[i] / 255
    }
    return result
  })
}

function plotChart(intensities, timeSeq, timeUnitName, logIntensity, graphColors, element) {
  if (!element || element.clientHeight === 0) {
    return
  }
  // IE 11
  if (window.navigator.userAgent.includes('Trident')) {
    console.log('D3.js is incompatible with IE11. Failed to render XIC plot.')
    return
  }

  if (intensities.length > graphColors.length) {
    console.log(`Mismatch between number of XIC plots (${intensities.length}) and their colors (${graphColors.length}).`
                  + ' Failed to render XIC plot.')
    return
  }

  d3.select(element).select('svg').remove()

  const margin = { top: 20, right: 40, bottom: 40, left: 50 }
  const width = element.clientWidth - margin.left - margin.right
  const height = element.clientHeight - margin.top - margin.bottom
  const originTranslation = { x: 20, y: -5 }
  const [minRt, maxRt] = d3.extent(timeSeq)
  const maxIntensity = d3.max(intensities.map(arr => d3.max(arr)))
  const minIntensity = logIntensity ? d3.min(intensities.map(arr => d3.min(arr))) : 0
  const xDomain = [d3.max([0, minRt - 1]), maxRt]
  const yDomain = [minIntensity, maxIntensity]

  const xScale = d3.scaleLinear().domain(xDomain).range([0, width - originTranslation.x])
  let yScale = logIntensity ? d3.scaleLog().base(10) : d3.scaleLinear()
  yScale = yScale.domain(yDomain).range([height, originTranslation.y])

  const xAxis = d3.axisBottom(xScale).ticks(5)
  const yAxis = d3.axisLeft(yScale).ticks(5, '.1e').tickPadding(5)

  const plotPoints = intensities.map(arr => d3.zip(timeSeq, arr))

  const dblClickTimeout = 400 // milliseconds
  let idleTimeout

  function brushHandler() {
    const s = d3.event.selection

    if (!s) { // click event
      if (!idleTimeout) {
        // not double click => wait for the second click
        idleTimeout = setTimeout(() => { idleTimeout = null }, dblClickTimeout)
        return idleTimeout
      }
      // double click => reset axes
      xScale.domain(xDomain)
      yScale.domain(yDomain)
    } else {
      const xDomainInterval = s.map((n) => n - originTranslation.x)
        .map(xScale.invert, xScale)

      // eslint-disable-next-line no-inner-declarations
      function calcMaxIntensity(pts) {
        const intensities = pts.filter(d => d[0] >= xDomainInterval[0] && d[0] <= xDomainInterval[1])
          .map(d => d[1])
        return (intensities.length > 0) ? d3.max(intensities) : 0
      }

      const intensityRange = [minIntensity, d3.max(plotPoints.map(arr => calcMaxIntensity(arr)))]
      xScale.domain(xDomainInterval)
      yScale.domain(intensityRange)
      brushLayer.call(brush.move, null) // remove the selection
    }

    const t = svg.transition().duration(300)
    gX.transition(t).call(xAxis)
    gY.transition(t).call(yAxis)

    update(t)
  }

  const container = d3.select(element).append('svg')
    .attr('width', element.clientWidth)
    .attr('height', element.clientHeight)

  const svg = container.append('g')
    .attr('transform', `translate(${margin.left}, ${margin.top})`)

  svg.append('defs')
    .append('clipPath')
    .attr('id', 'plot-clip')
    .append('rect')
    .attr('x', originTranslation.x)
    .attr('y', 2 * originTranslation.y)
    .attr('width', width - originTranslation.x)
    .attr('height', height - originTranslation.y)

  const gX = svg.append('g')
    .attr('transform', `translate(${originTranslation.x}, ${height + originTranslation.y})`)
    .call(xAxis)

  const gY = svg.append('g')
    .attr('transform', `translate(${originTranslation.x}, ${originTranslation.y})`)
    .call(yAxis)

  const gGraph = svg.append('g')
    .attr('clip-path', 'url(#plot-clip)')
  const graphs = []
  for (let i = 0; i < intensities.length; ++i) {
    graphs.push(gGraph.append('path')
      .attr('class', 'line')
      .attr('stroke', graphColors[i])
      .attr('stroke-width', 2)
      .attr('opacity', 1)
      .attr('fill', 'none'))
  }

  svg.append('text')
    .text(`Ion intensity${logIntensity ? ' (log)' : ''}`).style('text-anchor', 'middle')
    .attr('transform', `translate(-30, ${height / 2}) rotate(-90)`)

  svg.append('text')
    .text(`Retention time [${timeUnitName}]`).style('text-anchor', 'middle')
    .attr('transform', `translate(${width / 2}, ${height + 30}) `)

  const brush = d3.brushX()
    .extent([[originTranslation.x, 2 * originTranslation.y], [width, height + originTranslation.y]])
    .on('end', brushHandler)
  const brushLayer = svg.append('g').call(brush)

  function update(t) {
    let gs = graphs
    if (t) {
      gs = graphs.map(g => g.transition(t))
    }

    const drawPath = d3.line().x(d => xScale(d[0]))
      .y(d => yScale(d[1]))

    plotPoints.forEach((points, graphIdx) => {
      gs[graphIdx].attr('d', drawPath(points))
        .attr('transform', `translate(${originTranslation.x}, ${originTranslation.y})`)
    })
  }

  update()
}

export default {
  name: 'XicPlot',
  props: {
    intensityImgs: {
      type: Array,
      required: true,
    },
    graphColors: {
      type: Array,
      required: true,
    },
    acquisitionGeometry: {
      required: true,
    },
    logIntensity: {
      type: Boolean,
      default: false,
    },
    showLogIntSwitch: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      validIntImages: [],
      currentIntensities: [],
      internalLogIntensity: this.logIntensity,
    }
  },
  computed: {
    isReady() {
      return this.validIntImages
        && this.acquisitionGeometry
        && 'coord_list' in this.acquisitionGeometry.acquisition_grid
        && this.$refs.xicChart
        && this.$refs.xicChart.clientHeight
    },
  },
  watch: {
    intensityImgs: function() { this.reloadPlot() },
    graphColors: function() { this.reloadPlot() },
    acquisitionGeometry: function() { this.reloadPlot() },
    logIntensity: function() {
      if (this.logIntensity !== this.internalLogIntensity) {
        this.setLogIntensity(this.logIntensity)
      }
    },
  },
  mounted() {
    this.reloadPlot()
    if (window) {
      window.addEventListener('resize', () => this.reloadPlot())
    }
  },
  methods: {
    setLogIntensity(enabled) {
      this.internalLogIntensity = enabled
      this.reloadPlot()
    },
    reloadPlot() {
      if (this.intensityImgs.length !== this.graphColors.length) {
        return
      }
      this.validIntImages = this.intensityImgs.filter(intImg => intImg.url)
      if (this.isReady) {
        Promise.all(this.validIntImages.map(intImg => imageToIntensity(intImg.url, intImg.maxIntensity)))
          .then((intensities) => {
            this.currentIntensities = intensities
            this.updatePlot()
          }).catch((e) => {
            console.log(e)
          })
      }
    },
    updatePlot() {
      if (!this.currentIntensities) {
        throw new Error('XIC data not loaded')
      }
      if (this.acquisitionGeometry.length_unit !== 's') {
        console.log(`Unexpected LC time unit: ${this.acquisitionGeometry.length_unit}`)
      }
      const timeUnitName = 'min'
      const timeSeq = this.acquisitionGeometry.acquisition_grid.coord_list.map((pixel) => pixel[0] / 60)
      const lowerLogIntThreshold = this.validIntImages[0].maxIntensity * 0.01
      const intensitiesToPlot = this.internalLogIntensity
        ? this.currentIntensities
          .map(arr => arr.map(i => i < lowerLogIntThreshold ? lowerLogIntThreshold : i))
        : this.currentIntensities
      plotChart(intensitiesToPlot, timeSeq, timeUnitName, this.internalLogIntensity,
        this.graphColors.slice(0, intensitiesToPlot.length), this.$refs.xicChart)
    },
  },
}

</script>

<style>
.log-scale-switch {
  padding: 2px;
  position: absolute;
  left: 1em;
  bottom: 0.1em;
  font-size: inherit;
}
</style>
