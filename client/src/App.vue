<template>
  <div id="app">
    <router-view id="routerpanel"/>
  </div>
</template>

<style lang="scss" scoped>

#routerpanel{
    font-family: 'Robot-Light', sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    height: 100vh;
    width: 100vw;
    overflow: hidden;

    display: flex;
    flex-direction: row;
    flex-wrap: no-wrap;
      
    overflow-y: scroll;
}
</style>

<script lang="ts">
import {Vue, Component} from "vue-property-decorator";
import SideNav from "./components/SideNav.vue";

@Component
export default class App extends Vue {
}
</script>
