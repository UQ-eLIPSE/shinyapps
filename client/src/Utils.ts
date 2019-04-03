/**
 * Returns an M x N array where M is the number of outcomes and N is the amount.
 * For each column, the sum should result into the value of size.
 *
 * @example rmultinom(2, 3, [0.5, 0.5]) -> [[1, 2], [3, 0]]
 * @param amount The number lotteries to perform
 * @param size The number of rolls per a lottery
 * @param probabilities The probability for each type
 */
export function rmultinom(amount: number, size: number, probabilities: number[]) {
    // Return an array of [amount x size] with values randomly distributed
    // Instantiate the output
    const output: number[][] = [];

    // Calculate our ranges note the value is the min value. E.g. a[0] = 0.5 means values below 0.5 accepted
    const intervals: number[] = [];

    // TODO solve floating point errors

    for (let i = 0; i < probabilities.length; i++) {
        output.push([]);
        for (let j = 0; j < amount; j++) {

            output[i].push(0);
        }
        intervals.push(i > 0 ? probabilities[i] + intervals[i - 1] : probabilities[i]);

        // Floating index
        if (i === probabilities.length - 1) {
            intervals[i] = 1;
        }
    }

    // Next step is to do our lottery
    for (let i = 0; i < amount; i++) {
        for (let j = 0 ; j < size; j++) {
            // Increment the results based on the intervals
            const value = Math.random();
            const index = intervals.findIndex((element) => {
                return element >= value;
            });
            output[index][i] = output[index][i] + 1;
        }
    }

    return output;
}

/**
 * Returns a number array from min to max.
 * @example createXArray(1, 10) -> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 * @param min The min value range
 * @param max The max value range
 */
export function createXArray(min: number = 0, max: number): number[] {
    const output = [];

    for (let i = min; i <= max; i++) {
        output.push(i);
    }

    return output;
}

/**
 * Given a M x N matrix, return the transposed matrix of N x M
 * @example tranposeMatrix([[1,2,3], [4,5,6]]) -> [[1, 4], [2, 5], [3, 6]]
 * @param matrix an M x N array.
 */
export function transposeMatrix(matrix: number[][]): number[][] {

    // The general idea is iterate over N and M and push into the arrays.
    if (matrix.length && matrix[0].length) {
        const output: number[][] = [];

        // Grab dimensions
        const m = matrix.length;
        const n = matrix[0].length;
        for (let i = 0; i < n; i++) {
            output.push([]);
            for (let j = 0; j < m; j++) {
                output[i].push(matrix[j][i]);
            }
        }

        return output;
    } else {
        return [];
    }
}

/**
 * Returns an array of numbers of size observation amount. The numbers are based on the
 * number of coin flips determine by the 3 parameters.
 * @example rBinomialDistribution(3, 5, 0.5) -> [2, 3, 3]
 * @param observationAmount The number of observations to do
 * @param trialAmount The number of flips in a trial
 * @param probability The probability a flip is successful
 */
export function rBinomialDistribution(observationAmount: number, trialAmount: number, probability: number) {
    const output = [];

    for (let i = 0 ; i < observationAmount; i++) {
        let count = 0;

        for (let j = 0 ; j < trialAmount; j++) {
            const lotto = Math.random();

            if (probability >= lotto) {
                count = count + 1;
            }
        }

        output.push(count);
    }

    return output;
}

/**
 * Given an array, return an array with the sampled indices.
 * @example sample([1, 1, 1, 1, 1, 1], 2, false) -> [2, 5]
 * @example sample([1, 1, 1, 1, 1, 1], 4, true) -> [2, 2, 1, 4]
 * @param arr The array to sample
 * @param sampleAmount The amount of samples
 * @param replace Whether to replace or not
 */
export function sample<T>(arr: T[], sampleAmount: number, replace: boolean = false) {
    const output: number[] = [];

    const indices: number[] = [];

    for (let i = 0 ; i < sampleAmount; i++) {
        while (1) {
            const index = Math.round(Math.random() * arr.length);
            if (replace) {
                if (indices.find((element) => element === index) === null) {
                    indices.push(index);
                    output.push(index);
                    break;
                }
            } else {
                output.push(index);
                break;
            }
        }
    }

    return output;
}
