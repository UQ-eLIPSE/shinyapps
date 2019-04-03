<template>
    <div class="sidebar">
        <h2>Population parameters</h2>
        <div>
            <h3>Diploid population size</h3>
            <span>Current Value: {{displayPopulationSize}}</span>
            <div id="slider1"></div>
            
        </div>
        <div>
            <h3>Mutation Rate</h3>
            <select v-model.number="mutationRate">
                <option :value="0">0</option>
                <option :value="0.0005">1 / 500 (5e-3)</option>
                <option :value="0.0001">1 / 1000 (1e-3)</option>
                <option :value="0.0001">1 / 10000 (1e-4)</option>
                <option :value="0.00001">1 / 100000 (1e-5)</option>
                <option :value="0.000001">1 / 1000000 (1e-6)</option>
            </select>
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
export default class GeneMutationSimSideNav extends Vue {

    private populationSize: number = 10;
    private mutationRate: number = 0;

    private populationStep = 10;

    private displayPopulationSize: number = 10;

    private MIN_POPULATION = 10;
    private MAX_POPULATION = 20000;

    private mounted() {
        $("#slider1").slider({
            max: this.MAX_POPULATION,
            min: this.MIN_POPULATION,
            step: this.populationStep,
            change: (event, ui) => { this.populationSize = ui.value!; },
            slide: (event, ui) => { this.displayPopulationSize = ui.value!; }
        });

    }

    private runSimulation() {

        EventBus.$emit(EventBusEvents.RUN_SIMULATION, this.populationSize,
                       this.mutationRate);
    }
}
</script>
