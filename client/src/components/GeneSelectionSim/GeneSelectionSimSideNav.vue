<template>
    <div class="sidebar">
        <h2>Population parameters</h2>
        <div>
            <input v-model="infinitePopulation" id="infPop" type="checkbox"/> Infinite Population?
        </div>        
        <div>
            <h3>Diploid population size</h3>
            <span>Current Value: {{displayPopulationSize}}</span>
            <div id="slider1"></div>
            
        </div>
        <div>
            <h3>Selective Advantage of allele R, relative to W</h3>
            <span>Current Value: {{displayAdvantage}}</span>
            <div id="slider2"></div>
        </div>
        <div>
            <h3>Allele frequency of R</h3>
            <span>Allele Frequency of R: {{displayFrequency}}</span>
            <div id="slider3"></div>
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
export default class GeneSelectionSimSideNav extends Vue {
    private infinitePopulation: boolean = false;
    private populationSize: number = 10;
    private advantage: number = 0;
    private frequency: number = 0;

    private displayPopulationSize: number = 10;
    private displayAdvantage: number = 0;
    private displayFrequency: number = 0;

    private MIN_POPULATION = 10;
    private MAX_POPULATION = 1000;

    private MIN_ADVANTAGE = -0.1;
    private MAX_ADVANTAGE = 0.1;

    private MIN_FREQUENCY = 0;
    private MAX_FREQUENCY = 1;

    private populationStep = 10;
    private advantageStep = 0.005;
    private frequencyStep = 0.05;

    private mounted() {
        $("#slider1").slider({
            max: this.MAX_POPULATION,
            min: this.MIN_POPULATION,
            step: this.populationStep,
            change: (event, ui) => { this.populationSize = ui.value!; },
            slide: (event, ui) => { this.displayPopulationSize = ui.value!; },
        });

        $("#slider2").slider({
            max: this.MAX_ADVANTAGE,
            min: this.MIN_ADVANTAGE,
            step: this.advantageStep,
            change: (event, ui) => { this.advantage = ui.value!; },
            slide: (event, ui) => { this.displayAdvantage = ui.value!; }
        });

        $("#slider3").slider({
            max: this.MAX_FREQUENCY,
            min: this.MIN_FREQUENCY,
            step: this.frequencyStep,
            change: (event, ui) => { this.frequency = ui.value!; },
            slide: (event, ui) => { this.displayFrequency = ui.value!; }
        });

    }

    private runSimulation() {
        EventBus.$emit(EventBusEvents.RUN_SIMULATION, this.populationSize, this.advantage,
                       this.frequency, this.infinitePopulation);
    }
}
</script>
