<template>
    <div>
        <gene-selection-flow-sim-side-nav/>
        <div class="container">
            <h1>Experimental Site</h1>
            <div id="freq1">
            </div>
            <div id="freq2">
            </div>
            <div id="prop1">
            </div>
            <div id="prop2">
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
import GeneSelectionFlowSimSideNav from "./GeneSelectionFlowSimSideNav.vue";

enum PopulationType {
    POPULATION_1 = "Pop1",
    POPULATION_2 = "Pop2"
}

// No clean way of getting number of enums. Use a constant
const NUM_POP_TYPES = 2;
const NUM_ALLELES = 2;
const NUM_GENO_TYPES = 3;

const defaultXaxis = [0, 100];
const defaultYaxis = [0, 1];

interface FrequencyTableEntry {
    GENERATION: number;
    ALLELE: string;
    FREQUENCY: number;
    POPULATION_TYPE?: PopulationType;
}

interface GenoTypeProportionEntry {
    GENERATION?: number;
    GENOTYPE: string;
    PROPORTION: number;
    POPULATION_TYPE?: PopulationType;
}

interface GenoConstantEntry {
    GENOTYPE: string;
    AMOUNT: number;
}

@Component({
    components: {
        GeneSelectionFlowSimSideNav
    }
})
export default class GeneflowSim extends Vue {
    private mounted() {
        EventBus.$on(EventBusEvents.RUN_SIMULATION, this.handleSimulationRun);
    }

    private beforeDestroy() {
        EventBus.$off(EventBusEvents.RUN_SIMULATION);
    }

    private handleSimulationRun(populationSize: number, advantage1: number, advantage2: number, migrantProp1: number,
                                migrantProp2: number, freqAllele1: number, freqAllele2: number,
                                infinitePopulation: boolean) {

        if (populationSize > 0) {
            if (Math.round(populationSize * migrantProp1) < 1 && migrantProp1 !== 0) {
                alert("The migration rate m1 > 0, but N * m1 < 1: Cannot have < 1 migrants/generation.");
                return;
            } else if (Math.round(populationSize * migrantProp2) < 1 && migrantProp2 !== 0) {
                alert("The migration rate m2 > 0, but N * m2 < 1: Cannot have < 1 migrants/generation.");
                return;
            }
        }

        // Do the simulation
        this.computeSimulation(populationSize, advantage1, advantage2, migrantProp1, migrantProp2,
                               freqAllele1, freqAllele2, infinitePopulation);
    }

    private computeSimulation(populationSize: number, advantage1: number, advantage2: number, migrantProp1: number,
                              migrantProp2: number, freqAllele1: number, freqAllele2: number,
                              infinitePopulation: boolean) {
        const generations = 100;
        // Initial values
        let freqTable: FrequencyTableEntry[] = [{
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            ALLELE: "R",
            FREQUENCY: freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            ALLELE: "W",
            FREQUENCY: 1 - freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            ALLELE: "R",
            FREQUENCY: freqAllele2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            ALLELE: "W",
            FREQUENCY: 1 - freqAllele2
        }];

        let genoTable: GenoTypeProportionEntry[] = [{
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "R/R",
            PROPORTION: freqAllele1 * freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "R/W",
            PROPORTION: freqAllele1 * (1 - freqAllele1) * 2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "W/W",
            PROPORTION: (1 - freqAllele1) * (1 - freqAllele1)
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "R/R",
            PROPORTION: freqAllele2 * freqAllele2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "R/W",
            PROPORTION: freqAllele2 * (1 - freqAllele2) * 2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "W/W",
            PROPORTION: (1 - freqAllele2) * (1 - freqAllele2)
        }];



        const constantsPop1: GenoConstantEntry[] = [{
            GENOTYPE: "R/R",
            AMOUNT: 1
        }, {
            GENOTYPE: "R/W",
            AMOUNT: 1
        }, {
            GENOTYPE: "W/W",
            AMOUNT: 1
        }];

        const constantsPop2: GenoConstantEntry[] = [{
            GENOTYPE: "R/R",
            AMOUNT: 1
        }, {
            GENOTYPE: "R/W",
            AMOUNT: 1
        }, {
            GENOTYPE: "W/W",
            AMOUNT: 1
        }];

        const postSelection = [];

        // Based on advantages modify the constantsPop
        if (advantage1 > 0) {
            constantsPop1[1].AMOUNT = constantsPop1[1].AMOUNT - advantage1;
            constantsPop1[2].AMOUNT = constantsPop1[2].AMOUNT - (2 * advantage1);
        } else {
            constantsPop1[0].AMOUNT = constantsPop1[0].AMOUNT + (2 * advantage1);
            constantsPop1[1].AMOUNT = constantsPop1[1].AMOUNT + advantage1;
        }

        if (advantage2 > 0) {
            constantsPop2[1].AMOUNT = constantsPop2[1].AMOUNT - advantage2;
            constantsPop2[2].AMOUNT = constantsPop2[2].AMOUNT - (2 * advantage2);
        } else {
            constantsPop2[0].AMOUNT = constantsPop2[0].AMOUNT + (2 * advantage2);
            constantsPop2[1].AMOUNT = constantsPop2[1].AMOUNT + advantage2;
        }

        for (let i = 2; i <= generations; i++) {
            const preSelection = freqTable.filter((element) => {
                return element.GENERATION === i - 1;
            });

            const postMig = this.geneflow_sim(populationSize, migrantProp1, migrantProp2,
                                              preSelection.find((element) => {
                return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.ALLELE === "R";
            })!.FREQUENCY, preSelection.find((element) => {
                return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.ALLELE === "R";
            })!.FREQUENCY, infinitePopulation, 2);

            for (let j = 0 ; j < NUM_POP_TYPES; j++) {

                let referredConstants: GenoConstantEntry[];
                let referredPop: PopulationType;
                switch (j) {
                    case 0:
                        referredConstants = constantsPop1;
                        referredPop = PopulationType.POPULATION_1;
                        break;
                    case 1:
                    default:
                        referredConstants = constantsPop2;
                        referredPop = PopulationType.POPULATION_2;
                        break;
                }

                const genos = postMig.filter((element) => {
                    return element.POPULATION_TYPE === referredPop && element.GENERATION === 2;
                });

                const popOverallFitness = referredConstants.reduce((count, element) => {
                    const tempGenosProp = genos.find((ele) => element.GENOTYPE === ele.GENOTYPE)!.PROPORTION;

                    count = count + (element.AMOUNT * tempGenosProp);
                    return count;
                }, 0);

                const genoSelection: GenoTypeProportionEntry[] = [];
                for (let k = 0; k < NUM_GENO_TYPES; k++) {
                    let referredGenoType: string;

                    switch (k) {
                        case 0:
                            referredGenoType = "R/R";
                            break;
                        case 1:
                            referredGenoType = "R/W";
                            break;
                        case 2:
                        default:
                            referredGenoType = "W/W";
                            break;
                    }

                    genoSelection.push({
                        GENERATION: i,
                        GENOTYPE: referredGenoType,
                        PROPORTION: referredConstants.find((element) =>
                                                            element.GENOTYPE === referredGenoType)!.AMOUNT *
                                                            genos.find((element) => element.POPULATION_TYPE ===
                                                                                    referredPop && element.GENOTYPE ===
                                                                                    referredGenoType)!.PROPORTION /
                                                                                    popOverallFitness,
                        POPULATION_TYPE: referredPop
                    });

                }

                const freqSelection: FrequencyTableEntry[] = [];

                const popR = ((2 * genoSelection.find((element) => {
                    return element.GENOTYPE === "R/R";
                })!.PROPORTION) + genoSelection.find((element) => {
                    return element.GENOTYPE === "R/W";
                })!.PROPORTION) / 2;

                const popW = ((2 * genoSelection.find((element) => {
                    return element.GENOTYPE === "W/W";
                })!.PROPORTION) + genoSelection.find((element) => {
                    return element.GENOTYPE === "R/W";
                })!.PROPORTION) / 2;

                genoTable = genoTable.concat(genoSelection);
                freqTable = freqTable.concat([{
                    GENERATION: i,
                    POPULATION_TYPE: referredPop,
                    ALLELE: "R",
                    FREQUENCY: popR
                }, {
                    GENERATION: i,
                    POPULATION_TYPE: referredPop,
                    ALLELE: "W",
                    FREQUENCY: popW
                }]);
            }
        }
        // Start graphing. Layout constant
        const layoutFreq: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${infinitePopulation ? "Infinite" : populationSize}`,
            yaxis: {
                title: "Frequency",
                range: defaultYaxis
            },
            xaxis: {
                title: "Generation",
                range: defaultXaxis
            }
        };

        const layoutProp: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${infinitePopulation ? "Infinite" : populationSize}`,
            yaxis: {
                title: "Proportion",
                range: defaultYaxis
            },
            xaxis: {
                title: "Generation",
                range: defaultXaxis
            },
            barmode: "stack"
        };

        for (let i = 0 ; i < NUM_POP_TYPES; i++) {
            // Graph configurations
            const tracesFreq: Array<Partial<PlotData>> = [];
            const tracesProp: Array<Partial<PlotData>> = [];
            // References for filter
            let refPop: PopulationType;
            let refFreqGraph: string;
            let refPropGraph: string;

            switch (i) {
                case 0:
                    refPop = PopulationType.POPULATION_1;
                    refFreqGraph = "freq1";
                    refPropGraph = "prop1";
                    break;
                case 1:
                default:
                    refPop = PopulationType.POPULATION_2;
                    refFreqGraph = "freq2";
                    refPropGraph = "prop2";
                    break;
            }

            for (let j = 0; j < NUM_ALLELES; j++) {
                // Ref allele
                let refAllele: string;
                switch (j) {
                    case 0:
                        refAllele = "R";
                        break;
                    case 1:
                    default:
                        refAllele = "W";
                        break;
                }

                const traceFreq: Partial<PlotData> = {
                    x: freqTable.reduce((arr: number[], element) => {
                        if ((element.ALLELE === refAllele) && (element.POPULATION_TYPE === refPop)) {
                            arr.push(element.GENERATION);
                        }
                        return arr;
                    }, []),
                    y: freqTable.reduce((arr: number[], element) => {
                        if ((element.ALLELE === refAllele) && (element.POPULATION_TYPE === refPop)) {
                            arr.push(element.FREQUENCY);
                        }

                        return arr;
                    }, []),
                    type: "scatter",
                    name: refAllele
                };

                tracesFreq.push(traceFreq);
            }

            for (let j = 0; j < NUM_GENO_TYPES; j++) {
                let refGeno: string;
                switch (j) {
                    case 0:
                        refGeno = "R/R";
                        break;
                    case 1:
                        refGeno = "W/W";
                        break;
                    case 2:
                    default:
                        refGeno = "R/W";
                        break;
                }

                const traceProp: Partial<PlotData> = {
                    x: genoTable.reduce((arr: number[], element) => {
                        if ((element.GENOTYPE === refGeno) && (element.POPULATION_TYPE === refPop)) {
                            arr.push(element.GENERATION!);
                        }
                        return arr;
                    }, []),
                    y: genoTable.reduce((arr: number[], element) => {
                        if ((element.GENOTYPE === refGeno) && (element.POPULATION_TYPE === refPop)) {
                            arr.push(element.PROPORTION);
                        }

                        return arr;
                    }, []),
                    type: "bar",
                    name: refGeno
                };

                tracesProp.push(traceProp);
            }
            Plotly.react(refFreqGraph, tracesFreq, layoutFreq);
            Plotly.react(refPropGraph, tracesProp, layoutProp);
        }
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

    private geneflow_sim(populationSize: number, migrantProp1: number,
                         migrantProp2: number, freqAllele1: number, freqAllele2: number,
                         infinitePopulation: boolean, generations: number = 100): GenoTypeProportionEntry[] {

        // Initial values
        const freqTable: FrequencyTableEntry[] = [{
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            ALLELE: "R",
            FREQUENCY: freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            ALLELE: "W",
            FREQUENCY: 1 - freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            ALLELE: "R",
            FREQUENCY: freqAllele2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            ALLELE: "W",
            FREQUENCY: 1 - freqAllele2
        }];

        const genoTable: GenoTypeProportionEntry[] = [{
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "R/R",
            PROPORTION: freqAllele1 * freqAllele1
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "R/W",
            PROPORTION: freqAllele1 * (1 - freqAllele1) * 2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_1,
            GENOTYPE: "W/W",
            PROPORTION: (1 - freqAllele1) * (1 - freqAllele1)
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "R/R",
            PROPORTION: freqAllele2 * freqAllele2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "R/W",
            PROPORTION: freqAllele2 * (1 - freqAllele2) * 2
        }, {
            GENERATION: 1,
            POPULATION_TYPE: PopulationType.POPULATION_2,
            GENOTYPE: "W/W",
            PROPORTION: (1 - freqAllele2) * (1 - freqAllele2)
        }];

        for (let i = 2; i <= generations; i++) {

            let RR_1: number;
            let RW_1: number;
            let WW_1: number;
            let RR_2: number;
            let RW_2: number;
            let WW_2: number;


            if (infinitePopulation) {
                // Grab the previous generations population. Note we assume that there is only one value that matches
                // the filter
                const pop1 = freqTable.filter((element) => {
                    return element.GENERATION === i - 1 && element.POPULATION_TYPE === PopulationType.POPULATION_1 &&
                            element.ALLELE === "R";
                })[0].FREQUENCY;

                const pop2 = freqTable.filter((element) => {
                    return element.GENERATION === i - 1 && element.POPULATION_TYPE === PopulationType.POPULATION_2 &&
                            element.ALLELE === "R";
                })[0].FREQUENCY;

                // New proportion of genotype depends on current proportion in PopX, migration into PopX
                // and the proportion of that genotype in PopY: (1-m)xi + m(yi), where i is the ith
                // genotype, and x and y are their respective proportions in each population, and m is
                // the rate of migration into PopX.

                const x: GenoTypeProportionEntry[] = [{
                    POPULATION_TYPE: PopulationType.POPULATION_1,
                    GENOTYPE: "R/R",
                    PROPORTION: pop1 * pop1,
                }, {
                    POPULATION_TYPE: PopulationType.POPULATION_1,
                    GENOTYPE: "R/W",
                    PROPORTION: 2 * pop1 * (1 - pop1),
                }, {
                    POPULATION_TYPE: PopulationType.POPULATION_1,
                    GENOTYPE: "W/W",
                    PROPORTION: (1 - pop1) * (1 - pop1),
                }, {
                    POPULATION_TYPE: PopulationType.POPULATION_2,
                    GENOTYPE: "R/R",
                    PROPORTION: pop2 * pop2,
                }, {
                    POPULATION_TYPE: PopulationType.POPULATION_2,
                    GENOTYPE: "R/W",
                    PROPORTION: 2 * pop2 * (1 - pop2),
                }, {
                    POPULATION_TYPE: PopulationType.POPULATION_2,
                    GENOTYPE: "W/W",
                    PROPORTION: (1 - pop2) * (1 - pop2),
                }];

                RR_1 = (1 - migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "R/R";
                })[0].PROPORTION + (migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "R/R";
                })[0].PROPORTION;

                RW_1 = (1 - migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "R/W";
                })[0].PROPORTION + (migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "R/W";
                })[0].PROPORTION;

                WW_1 = (1 - migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "W/W";
                })[0].PROPORTION + (migrantProp1) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "W/W";
                })[0].PROPORTION;

                RR_2 = (1 - migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "R/R";
                })[0].PROPORTION + (migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "R/R";
                })[0].PROPORTION;

                RW_2 = (1 - migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "R/W";
                })[0].PROPORTION + (migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "R/W";
                })[0].PROPORTION;

                WW_2 = (1 - migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENOTYPE === "W/W";
                })[0].PROPORTION + (migrantProp2) * x.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENOTYPE === "W/W";
                })[0].PROPORTION;

            } else {
                const pop1 = freqTable.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_1 && element.GENERATION === i - 1;
                });

                const pop2 = freqTable.filter((element) => {
                    return element.POPULATION_TYPE === PopulationType.POPULATION_2 && element.GENERATION === i - 1;
                });

                // Compute the local off spring
                const offspring1 = this.make_offspring(i, pop1, populationSize *
                                                       (1 - migrantProp1)).genotypesProportion;
                const offspring2 = this.make_offspring(i, pop2, populationSize *
                                                       (1 - migrantProp2)).genotypesProportion;

                // Migrant offpsring into pop1
                let migrant1: GenoTypeProportionEntry[];
                if (Math.round(populationSize * migrantProp1) >= 1) {
                    migrant1 = this.make_offspring(i, pop2, populationSize * migrantProp1).genotypesProportion;
                } else {
                    migrant1 = [{
                        GENOTYPE: "R/R",
                        PROPORTION: 0
                    }, {
                        GENOTYPE: "R/W",
                        PROPORTION: 0
                    }, {
                        GENOTYPE: "W/W",
                        PROPORTION: 0
                    }];
                }

                // Migrant offpsring into pop1
                let migrant2: GenoTypeProportionEntry[];
                if (Math.round(populationSize * migrantProp2) >= 1) {
                    migrant2 = this.make_offspring(i, pop1, populationSize * migrantProp2).genotypesProportion;
                } else {
                    migrant2 = [{
                        GENOTYPE: "R/R",
                        PROPORTION: 0
                    }, {
                        GENOTYPE: "R/W",
                        PROPORTION: 0
                    }, {
                        GENOTYPE: "W/W",
                        PROPORTION: 0
                    }];
                }

                RR_1 = (1 - migrantProp1) * offspring1.filter((element) => {
                    return element.GENOTYPE === "R/R";
                })[0].PROPORTION + (migrantProp1) * migrant1.filter((element) => {
                    return element.GENOTYPE === "R/R";
                })[0].PROPORTION;

                RW_1 = (1 - migrantProp1) * offspring1.filter((element) => {
                    return element.GENOTYPE === "R/W";
                })[0].PROPORTION + (migrantProp1) * migrant1.filter((element) => {
                    return element.GENOTYPE === "R/W";
                })[0].PROPORTION;

                WW_1 = (1 - migrantProp1) * offspring1.filter((element) => {
                    return element.GENOTYPE === "W/W";
                })[0].PROPORTION + (migrantProp1) * migrant1.filter((element) => {
                    return element.GENOTYPE === "W/W";
                })[0].PROPORTION;

                RR_2 = (1 - migrantProp2) * offspring2.filter((element) => {
                    return element.GENOTYPE === "R/R";
                })[0].PROPORTION + (migrantProp2) * migrant2.filter((element) => {
                    return element.GENOTYPE === "R/R";
                })[0].PROPORTION;

                RW_2 = (1 - migrantProp2) * offspring2.filter((element) => {
                    return element.GENOTYPE === "R/W";
                })[0].PROPORTION + (migrantProp2) * migrant2.filter((element) => {
                    return element.GENOTYPE === "R/W";
                })[0].PROPORTION;

                WW_2 = (1 - migrantProp2) * offspring2.filter((element) => {
                    return element.GENOTYPE === "W/W";
                })[0].PROPORTION + (migrantProp2) * migrant2.filter((element) => {
                    return element.GENOTYPE === "W/W";
                })[0].PROPORTION;
            }

            const props = [[RR_1, RW_1, WW_1], [RR_2, RW_2, WW_2]];

            for (let j = 0; j < NUM_POP_TYPES; j++) {
                for (let k = 0; k < 3; k++) {
                    let genotype;
                    switch (k) {
                        case 0:
                            genotype = "R/R";
                            break;
                        case 1:
                            genotype = "R/W";
                            break;
                        case 2:
                        default:
                            genotype = "W/W";
                            break;
                    }
                    genoTable.push({
                        GENERATION: i,
                        POPULATION_TYPE: j === 0 ? PopulationType.POPULATION_1 : PopulationType.POPULATION_2,
                        GENOTYPE: genotype,
                        PROPORTION: props[j][k]
                    });
                }
            }
        }

        return genoTable;
    }
}

</script>
