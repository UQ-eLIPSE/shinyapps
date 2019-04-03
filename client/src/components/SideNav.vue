<template>
    <div class="sidebar">
        <h1>Simulations</h1>
        <router-link to="/drift-sim">Drift Simulation</router-link>
        <router-link to="/flow-sim">Flow Simulation</router-link>
        <router-link to="/selection-sim">Selection Simulation</router-link>
        <router-link to="/mutation-sim">Mutation Simulation</router-link>
        <router-link to="/selection-flow-sim">Selection Flow Simulation</router-link>

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
