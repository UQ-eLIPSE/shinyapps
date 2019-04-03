<template>
    <div>
        <side-nav/>
        <div class="container">    
        </div>
    </div>
</template>

<style scoped>
.container {
    padding: 40px;
    width: 100%;
}
</style>

<script lang="ts">
import { Vue, Component } from "vue-property-decorator";
import Plotly, { PlotData } from "plotly.js";
import { EventBus, EventBusEvents } from "../EventBus";
import { rmultinom, createXArray, transposeMatrix } from "../Utils";
import SideNav from "./SideNav.vue";

interface FrequencyTableEntry {
    GENERATION: number;
    ALLELE: string;
    FREQUENCY: number;
}

interface GenoTypeProportionEntry {
    GENERATION: number;
    GENOTYPE: string;
    PROPORTION: number;
}

@Component({
    components: {
        SideNav
    }
})
export default class Landing extends Vue {

}

</script>
