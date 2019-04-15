<template>
    <div>
        <gene-selection-sim-side-nav/>
        <div class="container">
            <div id="freq">
            </div>
            <div id="prop">
            </div>        
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
import { EventBus, EventBusEvents } from "../../EventBus";
import { rmultinom, createXArray, transposeMatrix } from "../../Utils";
import GeneSelectionSimSideNav from "./GeneSelectionSimSideNav.vue";
import { StyleGuide } from "../../colours_schemes";

const NUM_ALLELES = 2;
const NUM_GENO_TYPES = 3;

const defaultXaxis = [0, 100];
const defaultYaxis = [0, 1];

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

interface GenoConstantEntry {
    GENOTYPE: string;
    AMOUNT: number;
}

@Component({
    components: {
        GeneSelectionSimSideNav
    }
})
export default class GeneSelectionSim extends Vue {
    private mounted() {

        EventBus.$on(EventBusEvents.RUN_SIMULATION, this.handleSimulationRun);
    }

    private beforeDestroy() {
        EventBus.$off(EventBusEvents.RUN_SIMULATION);
    }

    private handleSimulationRun(populationSize: number, advantage: number, frequency: number,
                                infinitePopulation: boolean) {
        this.runSimulation(populationSize, advantage, frequency, infinitePopulation);
    }

    private runSimulation(populationSize: number, advantage: number, frequency: number, infinitePopulation: boolean) {
        const generations = 100;

        const freqTable: FrequencyTableEntry[] = [{
            GENERATION: 1,
            ALLELE: "R",
            FREQUENCY: frequency
        }, {
            GENERATION: 1,
            ALLELE: "W",
            FREQUENCY: 1 - frequency
        }];

        const genoTable: GenoTypeProportionEntry[] = [{
            GENERATION: 1,
            GENOTYPE: "R/R",
            PROPORTION: frequency * frequency
        }, {
            GENERATION: 1,
            GENOTYPE: "R/W",
            PROPORTION: frequency * (1 - frequency) * 2
        }, {
            GENERATION: 1,
            GENOTYPE: "W/W",
            PROPORTION: (1 - frequency) * (1 - frequency)
        }];

        const constants: GenoConstantEntry[] = [{
            GENOTYPE: "R/R",
            AMOUNT: 1
        }, {
            GENOTYPE: "R/W",
            AMOUNT: 1
        }, {
            GENOTYPE: "W/W",
            AMOUNT: 1
        }];

        // Based on advantages modify the constants
        if (advantage > 0) {
            constants[1].AMOUNT = constants[1].AMOUNT - advantage;
            constants[2].AMOUNT = constants[2].AMOUNT - (2 * advantage);
        } else {
            constants[0].AMOUNT = constants[0].AMOUNT + (2 * advantage);
            constants[1].AMOUNT = constants[1].AMOUNT + advantage;
        }

        for (let i = 2; i <= generations; i++) {
            // Allele at start of generation
            const R_G = freqTable.find((element) => {
                return element.GENERATION === i - 1 && element.ALLELE === "R";
            })!.FREQUENCY;


            let offSpring: GenoTypeProportionEntry[];

            if (infinitePopulation) {
                offSpring = [{
                    GENERATION: i,
                    PROPORTION: R_G * R_G,
                    GENOTYPE: "R/R"
                }, {
                    GENERATION: i,
                    PROPORTION: 2 * (1 - R_G) * R_G,
                    GENOTYPE: "R/W"
                }, {
                    GENERATION: i,
                    PROPORTION: (1 - R_G) * (1 - R_G),
                    GENOTYPE: "W/W"
                }];
            } else {
                offSpring = this.make_offspring(i, freqTable.filter((element) => {
                    return element.GENERATION === i - 1;
                }), populationSize).genotypesProportion;
            }

            // Find the fitness
            const populationFitness = (constants.find((element) => element.GENOTYPE === "R/R")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "R/R")!.PROPORTION) +
                                      (constants.find((element) => element.GENOTYPE === "R/W")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "R/W")!.PROPORTION) +
                                      (constants.find((element) => element.GENOTYPE === "W/W")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "W/W")!.PROPORTION);
            const RR_GS = (constants.find((element) => element.GENOTYPE === "R/R")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "R/R")!.PROPORTION) /
                                       populationFitness;

            const RW_GS = (constants.find((element) => element.GENOTYPE === "R/W")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "R/W")!.PROPORTION) /
                                       populationFitness;

            const WW_GS = (constants.find((element) => element.GENOTYPE === "W/W")!.AMOUNT *
                                       offSpring.find((element) => element.GENOTYPE === "W/W")!.PROPORTION) /
                                       populationFitness;

            // allele frequency post-selection
            const R_GS = ((2 * RR_GS) + RW_GS) / (2 * (RR_GS + RW_GS + WW_GS));

            freqTable.push({
                GENERATION: i,
                ALLELE: "R",
                FREQUENCY: R_GS
            }, {
                GENERATION: i,
                ALLELE: "W",
                FREQUENCY: 1 - R_GS
            });

            genoTable.push({
                GENERATION: i,
                GENOTYPE: "R/R",
                PROPORTION: RR_GS
            }, {
                GENERATION: i,
                GENOTYPE: "R/W",
                PROPORTION: RW_GS
            }, {
                GENERATION: i,
                GENOTYPE: "W/W",
                PROPORTION: WW_GS
            });
        }

        // Plot the rest of the data out
        // Start graphing. Layout constant
        const layoutFreq: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${infinitePopulation ? "Infinite" : populationSize}`,
            yaxis: {
                title: "Frequency",
                range: defaultYaxis,
                gridcolor: StyleGuide.WHITE
            },
            xaxis: {
                title: "Generation",
                range: defaultXaxis,
                gridcolor: StyleGuide.WHITE
            },
            plot_bgcolor: StyleGuide.GREY,
            paper_bgcolor: StyleGuide.GREY
        };

        const layoutProp: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${infinitePopulation ? "Infinite" : populationSize}`,
            yaxis: {
                title: "Proportion",
                range: defaultYaxis,
                gridcolor: StyleGuide.WHITE
            },
            xaxis: {
                title: "Generation",
                range: defaultXaxis,
                gridcolor: StyleGuide.WHITE
            },
            barmode: "stack",
            plot_bgcolor: StyleGuide.GREY,
            paper_bgcolor: StyleGuide.GREY
        };

        // Graph configurations
        const tracesFreq: Array<Partial<PlotData>> = [];
        const tracesProp: Array<Partial<PlotData>> = [];
        // References for filter
        const refFreqGraph: string = "freq";
        const refPropGraph: string = "prop";

        for (let j = 0; j < NUM_ALLELES; j++) {
            // Ref allele
            let refAllele: string;
            let colourString: StyleGuide;
            switch (j) {
                case 0:
                    refAllele = "R";
                    colourString = StyleGuide.RED;
                    break;
                case 1:
                default:
                    refAllele = "W";
                    colourString = StyleGuide.WHITE;
                    break;
            }

            const traceFreq: Partial<PlotData> = {
                x: freqTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === refAllele) {
                        arr.push(element.GENERATION);
                    }
                    return arr;
                }, []),
                y: freqTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === refAllele) {
                        arr.push(element.FREQUENCY);
                    }

                    return arr;
                }, []),
                type: "scatter",
                name: refAllele,
                line: {
                    color: colourString
                }
            };

            tracesFreq.push(traceFreq);
        }

        for (let j = 0; j < NUM_GENO_TYPES; j++) {
            let refGeno: string;
            let colourString: StyleGuide;
            switch (j) {
                case 2:
                    refGeno = "R/R";
                    colourString = StyleGuide.RED;
                    break;
                case 0:
                    refGeno = "W/W";
                    colourString = StyleGuide.WHITE;
                    break;
                case 1:
                default:
                    refGeno = "R/W";
                    colourString = StyleGuide.PLUM;
                    break;
            }



            const traceProp: Partial<PlotData> = {
                x: genoTable.reduce((arr: number[], element) => {
                    if (element.GENOTYPE === refGeno) {
                        arr.push(element.GENERATION!);
                    }
                    return arr;
                }, []),
                y: genoTable.reduce((arr: number[], element) => {
                    if (element.GENOTYPE === refGeno) {
                        arr.push(element.PROPORTION);
                    }

                    return arr;
                }, []),
                type: "bar",
                name: refGeno,
                marker: {
                    color: colourString
                }
            };

            tracesProp.push(traceProp);
        }
        Plotly.react(refFreqGraph, tracesFreq, layoutFreq);
        Plotly.react(refPropGraph, tracesProp, layoutProp);
    }

    private make_offspring(generationNumber: number, frequencyEntries: FrequencyTableEntry[],
                           numOffspring: number): { frequencyOutput: FrequencyTableEntry[],
                           genotypesProportion: GenoTypeProportionEntry[] } {
        // Get the allele names and geno types. Note order matters
        const ALLELE_NAMES: string[] = [];

        frequencyEntries.forEach((element) => {
            if (!ALLELE_NAMES.find((entry) => entry === element.ALLELE )) {
                ALLELE_NAMES.push(element.ALLELE);
            }
        });

        const genomeCombos = this.create_genome_combos(Array.from(ALLELE_NAMES));

        // Row = probability family, Col = Round number
        // E.g. 2 x 100 means 2 probabilities/alleles for a population 100
        const offspals = rmultinom(numOffspring, 2, frequencyEntries.reduce((arr: number[], element) => {
            arr.push(element.FREQUENCY);
            return arr;
        }, []));

        // Create the summation of frequencies
        const frequencyOutput: FrequencyTableEntry[] = [];


        for (let i = 0 ; i < ALLELE_NAMES.length; i++) {
            // Find the index that matches the allele name. Also divide by 2 for child purposes
            const freqProb = offspals[i].reduce((count, value) => {
                count = count + value;
                return count;
            }, 0) / (numOffspring * 2);

            frequencyOutput.push({
                GENERATION: generationNumber,
                ALLELE: ALLELE_NAMES[i],
                FREQUENCY: freqProb
            });
        }

        // Do the genetic allele proportions
        // On the cols (population size)

        /**
         * The idea is based on a proportion, assign the alleles.
         * E.g. [1, 1, 0, 1; 1, 1, 2, 1] should output ["R/W", "R/W", "W/W", "R/W"]
         */
        const transposedOffsPals = transposeMatrix(offspals);
        const genotypes: string[] = [];

        for (let i = 0; i < transposedOffsPals.length; i++) {
            // Use join to convert [R,R] to R/R
            const genotype = transposedOffsPals[i].reduce((arr: string[], element, index) => {
                // If we have 2 lots of R, push [R,R]
                // If we have 1 R and 1 W, push [R,W]
                for (let j = 0; j < element; j++) {
                    arr.push(ALLELE_NAMES[index]);
                }
                return arr;
            }, []).join("/");

            genotypes.push(genotype);
        }

        const genotypeEntry: GenoTypeProportionEntry[] = [];

        // Find the relative proportion
        for (let i = 0; i < genomeCombos.length; i++) {
            const proportion = genotypes.reduce((count, element) => {
                if (element === genomeCombos[i]) {
                    count = count + 1;
                }

                return count;
            }, 0) / numOffspring;

            genotypeEntry.push({
                PROPORTION: proportion,
                GENERATION: generationNumber,
                GENOTYPE: genomeCombos[i]
            });
        }

        // Recompute the table
        return { frequencyOutput, genotypesProportion: genotypeEntry };
    }

    private create_genome_combos(names: string[]) {
        // Essentially a combination of allelles. E.g. R and W -> R/R, R/W and W/W
        const output: string[] = [];
        for (let i = 0 ; i < names.length; i++) {
            for (let j = i; j < names.length; j++) {
                output.push(`${names[i]}/${names[j]}`);
            }
        }

        return output;
    }
}

</script>
