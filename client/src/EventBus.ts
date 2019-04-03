
import Vue from "vue";
export const EventBus = new Vue();

export enum EventBusEvents {
    RUN_SIMULATION = "RUN_SIMULATION"
}
