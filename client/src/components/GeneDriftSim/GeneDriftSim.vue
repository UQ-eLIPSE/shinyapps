<template>
    <div>
        <gene-drift-sim-side-nav/>
        <div class="container">
            <div id="frequency">
            </div>
            <div id="proportion">
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
import GeneDriftSimSideNav from "./GeneDriftSimSideNav.vue";
import { StyleGuide } from "../../colours_schemes";

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

const alleleTypes = ["R", "W"];
const genoTypes = ["W/W", "R/W", "R/R"];
const defaultYaxis = [0, 1];
@Component({
    components: {
        GeneDriftSimSideNav
    }
})
export default class GeneflowSim extends Vue {
    private mounted() {

        EventBus.$on(EventBusEvents.RUN_SIMULATION, this.handleSimulationRun);
    }

    private beforeDestroy() {
        EventBus.$off(EventBusEvents.RUN_SIMULATION);
    }

    private handleSimulationRun(populationSize: number, generations: number) {
        this.drift_simulation(populationSize, generations);
    }

    private drift_simulation(populationSize: number = 100, generations: number) {
        // Clear then enter

        let frequencyTable: FrequencyTableEntry[] = [{
            GENERATION: 1,
            ALLELE: "R",
            FREQUENCY: 0.5
        }, {
            GENERATION: 1,
            ALLELE: "W",
            FREQUENCY: 0.5
        }];

        // Note a proper insertion would be to loop through the array and find the missing generations
        let genoTypeTable: GenoTypeProportionEntry[] = [{
            GENERATION: 1,
            GENOTYPE: "R/W",
            PROPORTION: 1
        }];

        for (let i = 2; i <= generations; i++) {
            const simulatedOffspring = this.make_offspring(i, frequencyTable.filter((element) => {
                // Get the previous generation data
                return element.GENERATION === i - 1;
            }), populationSize);


            // TODO change simulatedOffspring to contain 2 values
            frequencyTable = frequencyTable.concat(simulatedOffspring.frequencyOutput);

            genoTypeTable = genoTypeTable.concat(simulatedOffspring.genotypesProportion);
        }


        // Define the allele array order

        // Graph configurations
        const tracesFreq: Array<Partial<PlotData>> = [];
        const layoutFreq: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${populationSize}`,
            yaxis: {
                title: "Frequency",
                gridcolor: StyleGuide.WHITE,
                range: defaultYaxis
            },
            xaxis: {
                title: "Generation",
                gridcolor: StyleGuide.WHITE
            },
            plot_bgcolor: StyleGuide.GREY,
            paper_bgcolor: StyleGuide.GREY
        };

        for (let i = 0; i < alleleTypes.length; i++) {

            const allele = alleleTypes[i];
            let refColour: StyleGuide = StyleGuide.BLACK;
            switch (allele) {
                case "W":
                    refColour = StyleGuide.WHITE;
                    break;
                case "R":
                    refColour = StyleGuide.RED;
                    break;
            }

            const trace: Partial<PlotData> = {
                x: frequencyTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === allele) {
                        arr.push(element.GENERATION);
                    }
                    return arr;
                }, []),
                y: frequencyTable.reduce((arr: number[], element) => {
                    if (element.ALLELE === allele) {
                        arr.push(element.FREQUENCY);
                    }

                    return arr;
                }, []),
                type: "scatter",
                name: allele,
                line: {
                    color: refColour
                }
            };

            tracesFreq.push(trace);
        }

        // Do the same with the genotypes
        const genoSet = new Set<string>();

        genoTypeTable.forEach((element) => {
            genoSet.add(element.GENOTYPE);
        });

        // Graph configurations
        const tracesProp: Array<Partial<PlotData>> = [];
        const layoutProp: Partial<Plotly.Layout> = {
            title: `Diploid population size = ${populationSize}`,
            yaxis: {
                title: "Proportion",
                gridcolor: StyleGuide.WHITE,
                range: defaultYaxis
            },
            xaxis: {
                title: "Generation",
                gridcolor: StyleGuide.WHITE
            },
            barmode: "stack",
            plot_bgcolor: StyleGuide.GREY,
            paper_bgcolor: StyleGuide.GREY
        };

        for (let i = 0; i < genoTypes.length; i++) {
            const genotype = genoTypes[i];

            let refColour: StyleGuide = StyleGuide.BLACK;
            switch (genotype) {
                case "W/W":
                    refColour = StyleGuide.WHITE;
                    break;
                case "R/R":
                    refColour = StyleGuide.RED;
                    break;
                case "R/W":
                    refColour = StyleGuide.PLUM;
                    break;
            }

            const trace: Partial<PlotData> = {
                x: genoTypeTable.reduce((arr: number[], element) => {
                    if (element.GENOTYPE === genotype) {
                        arr.push(element.GENERATION);
                    }
                    return arr;
                }, []),
                y: genoTypeTable.reduce((arr: number[], element) => {
                    if (element.GENOTYPE === genotype) {
                        arr.push(element.PROPORTION);
                    }

                    return arr;
                }, []),
                name: genotype,
                type: "bar",
                marker: {
                    color: refColour
                }
            };

            tracesProp.push(trace);
        }

        Plotly.react("frequency", tracesFreq, layoutFreq);
        Plotly.react("proportion", tracesProp, layoutProp);

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
