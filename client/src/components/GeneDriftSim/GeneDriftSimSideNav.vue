<template>
    <div class="sidebar">
        <h1>Drift simulation</h1>
        <h2>Population parameters</h2>
        <div>
            <h3>Diploid population size</h3>
            <span>Current Value: {{displayPopulationSize}}</span>
            <div id="slider1"></div>
            
        </div>
        <div>
            <h3>Generations</h3>
            <span>Current Value: {{displayGenerations}}</span>
            <div id="slider2"></div>
        </div>
        <button @click="runSimulation()" type="button">Run Simulation</button>
        <router-link to="/">Back</router-link>
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
import $ from "jquery";
import "jqueryui";
import { EventBus, EventBusEvents } from "../../EventBus";
@Component
export default class GeneDriftSimSideNav extends Vue {
    private populationSize: number = 10;
    private generations: number = 10;

    private displayPopulationSize: number = 10;
    private displayGenerations: number = 10;

    private MIN_POPULATION = 10;
    private MAX_POPULATION = 5000;

    private MIN_GENERATION = 10;
    private MAX_GENERATION = 100;

    private mounted() {
        $("#slider1").slider({
            max: this.MAX_POPULATION,
            min: this.MIN_POPULATION,
            change: (event, ui) => { this.populationSize = ui.value!; },
            slide: (event, ui) => { this.displayPopulationSize = ui.value!; }
        });

        $("#slider2").slider({
            max: this.MAX_GENERATION,
            min: this.MIN_GENERATION,
            change: (event, ui) => { this.generations = ui.value!; },
            slide: (event, ui) => { this.displayGenerations = ui.value!; }
        });

    }

    private runSimulation() {
        EventBus.$emit(EventBusEvents.RUN_SIMULATION, this.populationSize, this.generations);
    }
}
</script>
