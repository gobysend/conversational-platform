<template>
  <div
    class="small-2 report-card"
    :class="{ active: selected }"
    @click="onClick(index)"
  >
    <h3 class="heading">
      {{ heading }}
    </h3>

    <h4 class="point">
      <span>{{ point }}</span>

      <small class="desc">
        {{ desc }}
      </small>
    </h4>
  </div>
</template>
<script>
export default {
  props: {
    heading: { type: String, default: '' },
    point: { type: [Number, String], default: '' },
    index: { type: Number, default: null },
    desc: { type: String, default: '' },
    selected: Boolean,
    onClick: { type: Function, default: () => {} },
  },
};
</script>

<style lang="scss" scoped>
.report-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;

  .heading {
    font-size: 15px;
    font-weight: 500;
  }

  .point {
    span {
      font-weight: 400;
    }
  }
}
</style>
