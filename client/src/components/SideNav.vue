<template>
    <div class="sidebar">
        <h1>Simulations</h1>
        <router-link to="/drift-sim">Drift simulation</router-link>
        <router-link to="/flow-sim">Gene flow simulation</router-link>
        <router-link to="/selection-sim">Selection simulation</router-link>
        <router-link to="/mutation-sim">Mutation simulation</router-link>
        <router-link to="/selection-flow-sim">Selection and gene flow simulation</router-link>

    </div>
</template>

<style scoped>

.sidebar {
    background-color: #aaaaaa;
    min-width: 350px;
    max-width: 350px;
    padding: 15px 20px 0px 20px;
    width: 350px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    color: #FFFFFF;
}
</style>

<script lang="ts">
import { Vue, Component } from "vue-property-decorator";
@Component
export default class SideNav extends Vue {

}
</script>
