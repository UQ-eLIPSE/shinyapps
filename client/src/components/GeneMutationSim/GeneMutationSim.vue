<template>
    <div>
        <gene-mutation-sim-side-nav/>
        <div class="container">
            <h1>Experimental Site</h1>
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
import { rmultinom, createXArray, transposeMatrix, rBinomialDistribution, sample } from "../../Utils";
import GeneMutationSimSideNav from "./GeneMutationSimSideNav.vue";

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
    GENERATION?: number;
    GENOTYPE: string;
    PROPORTION: number;
}

@Component({
    components: {
        GeneMutationSimSideNav
    }
})
export default class GeneflowSim extends Vue {
    private mounted() {

        EventBus.$on(EventBusEvents.RUN_SIMULATION, this.handleSimulationRun);
    }

    private beforeDestroy() {
        EventBus.$off(EventBusEvents.RUN_SIMULATION);
    }

    private handleSimulationRun(populationSize: number, mutationRate: number) {

        // Do the simulation
        this.computeSimulation(populationSize, mutationRate);
    }

    private computeSimulation(populationSize: number, mutationRate: number, alleleFreq: number = 1) {

        const alleleSet = new Set<string>();
        alleleSet.add("1");
        const generations = 200;

        // Initial values
        let freqTable: FrequencyTableEntry[] = [{
            GENERATION: 1,
            ALLELE: "1",
            FREQUENCY: alleleFreq
        }];

        if (mutationRate !== 0) {
            freqTable.push({
                GENERATION: 1,
                ALLELE: "2",
                FREQUENCY: 1 - alleleFreq
            });

            alleleSet.add("2");
        }

        for (let i = 2; i <= generations; i++) {
            const mutationAmount = rBinomialDistribution(populationSize * 2,
                                                         1, mutationRate).reduce((count, element) => {
                count = count + element;
                return count;
            }, 0);

            if (mutationAmount > 0) {
                // There is a mutation

                // Based on the previous generation apply some mutations
                const previousGeneration = freqTable.filter((element) => {
                    return element.GENERATION === i - 1 && element.FREQUENCY !== 0;
                });

                const genePoolPre = previousGeneration.reduce((arr: string[], element) => {
                    for (let j = 0 ; j < Math.floor(element.FREQUENCY * populationSize * 2); j++) {
                        arr.push(element.ALLELE);
                    }

                    return arr;
                }, []);


                // The index of alleles to mutate
                const mutatedAlleles = sample(genePoolPre, mutationAmount, false);

                // Creation of new alleles
                const newAlleles = mutatedAlleles.reduce((arr: string[], element, index) => {
                    // Plus 1 due to alleles being 1-indexed
                    arr.push((index + alleleSet.size + 1).toString());
                    alleleSet.add((index + alleleSet.size + 1).toString());
                    return arr;
                }, []);

                // Mutate the adult gene pool
                const genePoolPost = genePoolPre;

                for (let j = 0 ; j < mutatedAlleles.length; j++) {
                    genePoolPost[mutatedAlleles[j]] = newAlleles[j];
                }

                // Get counts and allele frequencies in the mutated adult gene pool
                const countPost: {[key: string]: number} = {};

                for (let j = 0; j < genePoolPost.length; j++) {
                    if (countPost[genePoolPost[j]]) {
                        countPost[genePoolPost[j]] =  countPost[genePoolPost[j]] + 1;
                    } else {
                        countPost[genePoolPost[j]] = 1;
                    }
                }

                const freqPost: FrequencyTableEntry[] = Object.keys(countPost).reduce((arr: FrequencyTableEntry[],
                                                                                       allele) => {
                    arr.push({
                        GENERATION: i,
                        ALLELE: allele,
                        FREQUENCY: countPost[allele] / (populationSize * 2)
                    });
                    return arr;
                }, []);

                // Make the off spring and add them. Forcibly make mutations extinct due to floating point errors
                const offspring = this.make_offspring(i, freqPost,
                                                      populationSize).frequencyOutput.filter((element) => {
                    return element.FREQUENCY !== 0;
                });

                freqTable = freqTable.concat(offspring);

            } else {
                const offspring = this.make_offspring(i, freqTable.filter((element) => {
                    return element.GENERATION === i - 1 && element.FREQUENCY !== 0;
                }), populationSize).frequencyOutput.filter((element) => {
                    return element.FREQUENCY !== 0;
                });

                freqTable = freqTable.concat(offspring);
            }
        }

        // Start graphing. Layout constant
        const layoutFreq: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${populationSize}`,
            yaxis: {
                title: "Frequency",
                range: defaultYaxis
            },
            xaxis: {
                title: "Generation",
                range: defaultXaxis
            }
        };

        // Graph configurations
        const tracesFreq: Array<Partial<PlotData>> = [];
        // References for filter
        const refFreqGraph: string = "freq";

        const alleleArr = Array.from(alleleSet);
        for (let j = 0; j < alleleArr.length; j++) {

            const traceFreq: Partial<PlotData> = {
                x: freqTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === alleleArr[j]) {
                        arr.push(element.GENERATION);
                    }
                    return arr;
                }, []),
                y: freqTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === alleleArr[j]) {
                        arr.push(element.FREQUENCY);
                    }

                    return arr;
                }, []),
                type: "scatter",
                name: alleleArr[j]
            };

            tracesFreq.push(traceFreq);
        }

        Plotly.react(refFreqGraph, tracesFreq, layoutFreq);
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
