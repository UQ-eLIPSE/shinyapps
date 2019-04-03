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
            <h3>Selective Advantage of allele R, relative to W in Population 1</h3>
            <span>Current Value: {{displayAdvantage1}}</span>
            <div id="slider2"></div>
        </div>
        <div>
            <h3>Selective Advantage of allele R, relative to W in Population 2</h3>
            <span>Current Value: {{displayAdvantage2}}</span>
            <div id="slider3"></div>
        </div>                
        <div>
            <h3>% migrants into Population 1</h3>
            <span>Current Value: {{displayMigrantPop1}}</span>
            <div id="slider4"></div>
        </div>
        <div>
            <h3>% migrants into Population 2</h3>
            <span>Current Value: {{displayMigrantPop2}}</span>
            <div id="slider5"></div>
            
        </div>
        <div>
            <h3>Frequency of allele R in Population 1</h3>
            <span>Current Value: {{displayAllelePop1}}</span>
            <div id="slider6"></div>
        </div>
        <div>
            <h3>Frequency of allele R in Population 2</h3>
            <span>Current Value: {{displayAllelePop2}}</span>
            <div id="slider7"></div>
            
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
export default class GeneFlowSimSideNav extends Vue {
    private infinitePopulation = false;

    private populationSize: number = 10;
    private migrantPop1: number = 0;
    private migrantPop2: number = 0;
    private allelePop1: number = 0;
    private allelePop2: number = 0;
    private advantage1: number = 0;
    private advantage2: number = 0;

    private populationStep = 10;
    private advantageStep1 = 0.005;
    private advantageStep2 = 0.005;
    private migrantStep1 = 0.05;
    private migrantStep2 = 0.05;
    private alleleStep1 = 0.1;
    private alleleStep2 = 0.1;

    private displayPopulationSize: number = 10;
    private displayMigrantPop1: number = 0;
    private displayMigrantPop2: number = 0;
    private displayAllelePop1: number = 0;
    private displayAllelePop2: number = 0;
    private displayAdvantage1: number = 0;
    private displayAdvantage2: number = 0;


    private MIN_POPULATION = 10;
    private MAX_POPULATION = 20000;

    private MIN_MIGRANT_1 = 0;
    private MAX_MIGRANT_1 = 0.5;

    private MIN_MIGRANT_2 = 0;
    private MAX_MIGRANT_2 = 0.5;

    private MIN_ALLELE_1 = 0;
    private MAX_ALLELE_1 = 1;

    private MIN_ALLELE_2 = 0;
    private MAX_ALLELE_2 = 1;

    private MIN_ADVANTAGE_1 = -0.1;
    private MAX_ADVANTAGE_1 = 0.1;

    private MIN_ADVANTAGE_2 = -0.1;
    private MAX_ADVANTAGE_2 = 0.1;

    private mounted() {
        $("#slider1").slider({
            max: this.MAX_POPULATION,
            min: this.MIN_POPULATION,
            step: this.populationStep,
            change: (event, ui) => { this.populationSize = ui.value!; },
            slide: (event, ui) => { this.displayPopulationSize = ui.value!; }
        });

        $("#slider2").slider({
            max: this.MAX_ADVANTAGE_1,
            min: this.MIN_ADVANTAGE_1,
            step: this.advantageStep1,
            change: (event, ui) => { this.advantage1 = ui.value!; },
            slide: (event, ui) => { this.displayAdvantage1 = ui.value!; }
        });

        $("#slider3").slider({
            max: this.MAX_ADVANTAGE_2,
            min: this.MIN_ADVANTAGE_2,
            step: this.advantageStep2,
            change: (event, ui) => { this.advantage2 = ui.value!; },
            slide: (event, ui) => { this.displayAdvantage2 = ui.value!; }
        });

        $("#slider4").slider({
            max: this.MAX_MIGRANT_1,
            min: this.MIN_MIGRANT_1,
            step: this.migrantStep1,
            change: (event, ui) => { this.migrantPop1 = ui.value!; },
            slide: (event, ui) => { this.displayMigrantPop1 = ui.value!; }
        });

        $("#slider5").slider({
            max: this.MAX_MIGRANT_2,
            min: this.MIN_MIGRANT_2,
            step: this.migrantStep2,
            change: (event, ui) => { this.migrantPop2 = ui.value!; },
            slide: (event, ui) => { this.displayMigrantPop2 = ui.value!; }
        });

        $("#slider6").slider({
            max: this.MAX_ALLELE_1,
            min: this.MIN_ALLELE_1,
            step: this.alleleStep1,
            change: (event, ui) => { this.allelePop1 = ui.value!; },
            slide: (event, ui) => { this.displayAllelePop1 = ui.value!; }
        });

        $("#slider7").slider({
            max: this.MAX_ALLELE_2,
            min: this.MIN_ALLELE_2,
            step: this.alleleStep2,
            change: (event, ui) => { this.allelePop2 = ui.value!; },
            slide: (event, ui) => { this.displayAllelePop2 = ui.value!; }
        });

    }

    private runSimulation() {

        EventBus.$emit(EventBusEvents.RUN_SIMULATION, this.populationSize,
                       this.advantage1, this.advantage2, this.migrantPop1,
                       this.migrantPop2, this.allelePop1,
                       this.allelePop2, this.infinitePopulation);
    }
}
</script>
