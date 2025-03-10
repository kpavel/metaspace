<template>
  <div id="alignment-page">
    <div class="image-alignment-top">
      <div
        class="image-alignment-header"
        style="text-align: left"
      >
        <h3 style="margin: 5px; align-content: left">
          Optical image alignment for: <i>{{ datasetName }}</i>
        </h3>
        <p> <b>upload</b> an optical image, <b>align</b> an annotation image, then <b>submit</b></p>
        <el-button
          id="hintsButton"
          @click="toggleHints"
        >
          {{ showHints.text }}
        </el-button>
        <div
          v-if="showHints.status === true"
          id="hints"
        >
          <ul class="hint-list">
            <li>
              <img
                class="mouse-hint-icon"
                src="../../assets/translate-icon.png"
                title="Show/hide optical image"
              > Click and drag the annotation image to move it
            </li>
            <li>
              <img
                class="mouse-hint-icon"
                src="../../assets/zoom-icon.png"
                title="Show/hide optical image"
              > Use the mouse scroll wheel to zoom in and out
            </li>
            <li>
              <img
                class="mouse-hint-icon"
                src="../../assets/rotate-icon.png"
                title="Show/hide optical image"
              > Right-click and drag to rotate the annotation image
            </li>
            <li>
              <img
                class="mouse-hint-icon"
                src="../../assets/images-icon.png"
                title="Show/hide optical image"
              > Choose an annotation image with a recognisable spatial distribution
            </li>
            <li>
              <img
                class="mouse-hint-icon"
                src="../../assets/corners-icon.jpg"
                title="Show/hide optical image"
              > Double click the annotation image to enable fine tuning
            </li>
          </ul>
        </div>
      </div>
      <div class="image-alignment-settings">
        <div>
          <label class="optical-image-select el-button">
            <input
              type="file"
              class="input-optical-image"
              style="display: none;"
              accept=".jpg,.jpeg,.png"
              @change="onFileChange($event)"
            >
            Select optical image
          </label>

          <div style="padding: 3px; font-size: small;">
            {{ opticalImageFilename }}
          </div>

          <div
            slot="tip"
            class="el-upload__tip"
          >
            JPEG or PNG file less than {{ limitMB }}MB in size
          </div>
        </div>

        <div class="sliders-box">
          Optical image padding, px:
          <el-slider
            v-model="padding"
            :min="0"
            :max="500"
            :step="10"
          />

          IMS image opacity:
          <el-slider
            v-model="annotImageOpacity"
            :min="0"
            :max="1"
            :step="0.01"
          />
          <el-checkbox
            v-if="showTicOption"
            v-model="enableNormalization"
            :disabled="currentAnnotation && currentAnnotation.type === 'TIC Image'"
          >
            TIC normalization
          </el-checkbox>
        </div>

        <div class="annotation-selection">
          <span style="font-size: 14px; margin-bottom: 5px;">Annotation:</span>
          <el-pagination
            layout="prev,slot,next"
            :total="annotations ? annotations.length : 0"
            :page-size="1"
            :current-page="annotationIndex + 1"
            @current-change="updateIndex"
          >
            <el-select
              v-model="annotationIndex"
              filterable
              :loading="!annotations"
              class="annotation-short-info"
              @change="(newIdx) => updateIndex(newIdx + 1)"
            >
              <el-option
                v-for="(annot, i) in annotations"
                :key="annot.id"
                :value="i"
                :label="renderLabel(annot)"
              >
                <span v-html="renderAnnotation(annot)" />
              </el-option>
            </el-select>
          </el-pagination>

          Angle, °:
          <el-slider
            v-model="angle"
            :min="-180"
            :max="180"
            :step="0.1"
          />
        </div>

        <div class="optical-image-submit">
          <el-row
            :gutter="20"
            style="margin-bottom: 10px"
          >
            <el-col
              :span="12"
              :offset="opticalImgUrl ? 0 : 12"
            >
              <el-button @click="cancel">
                Cancel
              </el-button>
            </el-col>
            <el-col
              :span="12"
              :offset="opticalImgUrl ? 0 : 12"
            >
              <el-button
                v-show="opticalImgUrl"
                style="margin-bottom: 10px;"
                @click="reset"
              >
                Reset
              </el-button>
            </el-col>
          </el-row>
          <el-row :gutter="20">
            <el-col
              :span="12"
              :offset="opticalImgUrl ? 0 : 12"
            >
              <el-button
                v-show="opticalImgUrl"
                class="del-optical-image"
                @click="deleteOpticalImages"
              >
                Delete
              </el-button>
            </el-col>
            <el-col
              :span="12"
              :offset="opticalImgUrl ? 0 : 12"
            >
              <el-button
                type="primary"
                :disabled="!opticalImgUrl"
                @click="submit"
              >
                Submit
              </el-button>
            </el-col>
          </el-row>
        </div>
      </div>
    </div>
    <image-aligner
      v-if="opticalImgUrl && !hasNormalizationError"
      ref="aligner"
      style="position:relative;top:0px;z-index:1;"
      :annot-image-opacity="annotImageOpacity"
      :optical-src="opticalImgUrl"
      :tic-data="normalizationData"
      :initial-transform="initialTransform"
      :padding="padding"
      :rotation-angle-degrees="angle"
      :ion-image-src="massSpecSrc"
      @updateRotationAngle="updateAngle"
    />
    <div
      v-if="hasNormalizationError"
      class="normalization-error-wrapper"
    >
      <i class="el-icon-error info-icon mr-2" />
      <p class="text-lg">
        There was an error on normalization!
      </p>
    </div>
  </div>
</template>

<script>

import ImageAligner from './ImageAligner.vue'
import { annotationListQuery } from '../../api/annotation'
import {
  addOpticalImageQuery,
  deleteOpticalImageQuery,
  getDatasetDiagnosticsQuery,
  rawOpticalImageQuery,
} from '../../api/dataset'
import { renderMolFormula, renderMolFormulaHtml } from '../../lib/util'

import gql from 'graphql-tag'
import reportError from '../../lib/reportError'
import graphqlClient from '../../api/graphqlClient'
import { readNpy } from '@/lib/npyHandler'
import safeJsonParse from '@/lib/safeJsonParse'
import config from '@/lib/config'

export default {
  name: 'ImageAlignmentPage',
  components: {
    ImageAligner,
  },

  props: {
    limitMB: {
      type: Number,
      default: 50,
    },
    // service for storing raw optical images
    rawImageStorageUrl: {
      type: String,
      default: '/fs/raw_optical_images',
    },
  },

  data() {
    return {
      annotImageOpacity: 1,
      annotationIndex: 0,
      file: null,
      opticalImgUrl: null,
      ticData: null,
      alreadyUploaded: false,
      initialTransform: [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
      padding: 100,
      angle: 0,
      enableNormalization: false,
      showFullTIC: false,
      showHints: {
        status: true,
        text: 'Hide hints',
      },
      datasetName: '',
    }
  },

  apollo: {
    rawOpticalImage: {
      query: rawOpticalImageQuery,
      variables() {
        return { ds_id: this.datasetId }
      },
      update(data) {
        if (data.rawOpticalImage != null && data.rawOpticalImage.transform != null) {
          const { url, transform } = data.rawOpticalImage
          this.opticalImgUrl = url
          this.initialTransform = transform
          this.angle = 0
          this.alreadyUploaded = true
        }
      },
    },

    annotations: {
      query: annotationListQuery,
      variables() {
        return {
          filter: { fdrLevel: 0.5 },
          dFilter: { ids: this.datasetId },
          offset: 0,
          limit: 1000,
          query: '',
          orderBy: 'ORDER_BY_MSM',
          sortingOrder: 'DESCENDING',
          countIsomerCompounds: false,
        }
      },
      update(data) {
        // get normalization data for selected annotation
        const annotation = this.currentAnnotation || data.allAnnotations[0]
        this.updateNormalizationData(annotation)
        // add TIC reference
        if (config.features.tic && data.allAnnotations[0] && data.allAnnotations[0].id !== 'TIC Image') {
          const ticAnnotation = [{
            ...data.allAnnotations[0],
            id: 'TIC Image',
            type: 'TIC Image',
          }]
          data.allAnnotations = ticAnnotation.concat(data.allAnnotations)
          this.updateNormalizationData(ticAnnotation[0])
        }
        return data.allAnnotations
      },
    },

    datasetProperties: {
      query: gql`query getDatasetName($id: String!) {
                    dataset(id: $id) {
                      id
                      name
                      metadataType
                    }
                  }`,
      variables() {
        return { id: this.datasetId }
      },
      update(data) {
        this.datasetName = data.dataset.name

        // in case user just opened a link to optical image upload page w/o navigation in web-app,
        // filters are not set up
        this.$store.commit('replaceFilter', { metadataType: data.dataset.metadataType })
      },
    },
  },

  computed: {
    datasetId() {
      return this.$store.state.route.params.dataset_id
    },

    hasNormalizationError() {
      return this.enableNormalization && this.ticData
      && this.ticData.error
    },

    showTicOption() {
      return config.features.tic
    },

    normalizationData() {
      return (this.showFullTIC || this.enableNormalization) ? this.ticData : null
    },

    currentAnnotation() {
      if (!this.annotations || this.annotations.length === 0) {
        return null
      }
      return this.annotations[this.annotationIndex]
    },

    massSpecSrc() {
      const url = this.currentAnnotation ? this.currentAnnotation.isotopeImages[0].url : null
      return url || null
    },

    currentSumFormula() {
      if (!this.annotations) {
        return 'loading...'
      }
      if (this.annotations.length === 0) {
        return 'no results'
      }
      return this.renderAnnotation(this.currentAnnotation)
    },

    opticalImageFilename() {
      return this.file ? this.file.name : ''
    },
  },

  methods: {
    updateAngle(v) {
      if (v < -180) {
        v = 360 + v
      } else if (v > 180) {
        v = v - 360
      }
      this.angle = v
    },

    renderAnnotation(annotation) {
      const { ion } = annotation
      return annotation.type === 'TIC Image' ? 'TIC Image' : renderMolFormulaHtml(ion)
    },

    renderLabel(annotation) {
      const { ion } = annotation
      return annotation.type === 'TIC Image' ? 'TIC Image' : renderMolFormula(ion)
    },

    onFileChange(event) {
      const file = event.target.files[0]

      if (!file) {
        return
      }

      if (file.size > this.limitMB * 1024 * 1024) {
        this.$message({
          type: 'error',
          message: `The file exceeds ${this.limitMB} MB limit`,
        })
        return
      }

      window.URL.revokeObjectURL(this.opticalImgUrl)
      this.file = file
      this.opticalImgUrl = window.URL.createObjectURL(this.file)
      this.angle = 0
      this.initialTransform = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      this.alreadyUploaded = false
      document.querySelector('.input-optical-image').value = ''
    },
    updateIndex(newIdx) {
      this.annotationIndex = newIdx - 1
      this.updateNormalizationData(this.currentAnnotation)
    },
    async updateNormalizationData(currentAnnotation) {
      if (!currentAnnotation) {
        return null
      }

      try {
        const resp = await this.$apollo.query({
          query: getDatasetDiagnosticsQuery,
          variables: {
            id: currentAnnotation.dataset.id,
          },
          fetchPolicy: 'cache-first',
        })
        this.showFullTIC = currentAnnotation.type === 'TIC Image'
        const dataset = resp.data.dataset
        const tics = dataset.diagnostics.filter((diagnostic) => diagnostic.type === 'TIC')
        const tic = tics[0].images.filter((image) => image.key === 'TIC' && image.format === 'NPY')
        const { data, shape } = await readNpy(tic[0].url)
        const metadata = safeJsonParse(tics[0].data)
        metadata.maxTic = metadata.max_tic
        metadata.minTic = metadata.min_tic
        delete metadata.max_tic
        delete metadata.min_tic

        this.ticData = {
          data,
          shape,
          metadata: metadata,
          type: 'TIC',
          error: false,
          showFullTIC: currentAnnotation.type === 'TIC Image',
        }
      } catch (e) {
        this.ticData = {
          data: null,
          shape: null,
          metadata: null,
          showFullTIC: null,
          type: 'TIC',
          error: true,
        }
      }
    },
    async submit() {
      if (this.alreadyUploaded) {
        try {
          await this.addOpticalImage(this.opticalImgUrl)
          this.$message({
            type: 'success',
            message: 'The alignment has been updated',
          })
          this.$router.go(-1)
        } catch (e) {
          reportError(e)
        }
        return
      }

      const uri = this.rawImageStorageUrl + '/upload/'
      const xhr = new XMLHttpRequest()
      const fd = new FormData()
      xhr.open('POST', uri, true)
      xhr.responseType = 'json'
      xhr.onreadystatechange = async() => {
        if (xhr.readyState === 4 && xhr.status === 201) {
          const imageId = xhr.response.image_id
          const imageUrl = this.rawImageStorageUrl + '/' + imageId
          try {
            await this.addOpticalImage(imageUrl)
            this.$message({
              type: 'success',
              message: 'The image and alignment were successfully saved',
            })
            this.$router.go(-1)
          } catch (e) {
            reportError(e)
          }
        } else if (xhr.readyState === 4) {
          this.$message({
            type: 'error',
            message: "Couldn't upload the optical image due to server error",
          })
        }
      }
      fd.append('raw_optical_image', this.file)
      xhr.send(fd)
    },

    async addOpticalImage(imageUrl) {
      this.$message({
        message: 'Your optical image has been submitted! Please wait while it is saved...',
        type: 'success',
      })
      // TODO if there are no iso images found prevent optical image addition
      await this.$apollo.mutate({
        mutation: addOpticalImageQuery,
        variables: {
          datasetId: this.datasetId,
          imageUrl,
          transform: this.$refs.aligner.normalizedTransform,
        },
      })
      // Reset the GraphQL cache because thumbnails are cached.
      // Ideally this would just evict cached entries for this dataset, but apollo-cache's only other
      // cache eviction mechanism is so specific that it's hard to be sure that you've caught all affected queries.
      // It's better to waste bandwidth here than to lose time debugging cache issues in the future.
      await graphqlClient.cache.reset()
    },

    async deleteOpticalImages() {
      try {
        if (this.alreadyUploaded) {
          const graphQLResp = await this.$apollo.mutate({
            mutation: deleteOpticalImageQuery,
            variables: {
              id: this.datasetId,
            },
          })
          // Reset the GraphQL cache - see comment in addOpticalImage for rationale
          await graphqlClient.cache.reset()
          const resp = JSON.parse(graphQLResp.data.deleteOpticalImage)
          if (resp.status !== 'success') {
            this.$message({
              type: 'error',
              message: "Couldn't delete optical image due to an error",
            })
          } else {
            this.destroyOptImage()
            this.$message({
              type: 'success',
              message: 'The image and alignment were successfully deleted!',
            })
          }
        } else {
          this.destroyOptImage()
        }
      } catch (e) {
        reportError(e)
      }
    },

    destroyOptImage() {
      this.opticalImgUrl = window.URL.revokeObjectURL(this.opticalImgUrl)
      this.file = ''
    },

    reset() {
      this.$refs.aligner.reset()
      this.angle = 0
    },

    cancel() {
      this.$router.go(-1)
    },

    toggleHints() {
      this.showHints.status = !this.showHints.status

      if (this.showHints.status) {
        this.showHints.text = 'Hide hints'
      } else {
        this.showHints.text = 'Show hints'
      }
    },
  },
}

</script>

<style>

  .image-alignment-header {
    text-align: center;
    width: 100%;
    font-size: 14px;
    margin-bottom: 10px;
    padding: 10px;
    border-bottom: dotted lightblue 1px;
  }

  .image-alignment-settings {
    margin-bottom: 20px;
    padding: 10px;
    display: flex;
    flex-direction: row;
    justify-content: space-around;
  }

  .image-alignment-top {
    left: 0px;
    top: 62px;
    z-index: 500;
    width: 100%;
    background-color: white;
  }

  #alignment-page {
    margin: 20px;
  }

  .sliders-box {
    min-width: 150px;
    margin: 0px 20px;
    padding: 0px 20px;
    border-left: solid #eef 2px;
    font-size: 14px;
  }

  .annotation-short-info {
    display: inline-block;
    line-height: 23px;
    border-left: solid lightgrey 1px;
    border-right: solid lightgrey 1px;
    padding: 0px 10px;
    min-width: 180px;
    text-align: center;
  }

  .el-pagination .annotation-short-info .el-input {
    width: 180px;
  }

  .optical-image-submit {
    margin-left: 30px;
  }

  .optical-image-submit, .annotation-selection {
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  .mouse-hint-icon {
    width:  20px;
    height: 20px;
  }

  .hint-list{
    list-style-type: none;
  }

  .normalization-error-wrapper{
    height: 537px;
    width: 100%;
    @apply flex items-center justify-center;
  }
  .info-icon{
    font-size: 20px;
  }

</style>
