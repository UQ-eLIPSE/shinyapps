import Vue from "vue";
import Router from "vue-router";
import Landing from "./components/Landing.vue";
import GeneDriftSim from "./components/GeneDriftSim/GeneDriftSim.vue";
import GeneFlowSim from "./components/GeneFlowSim/GeneFlowSim.vue";
import GeneSelectionSim from "./components/GeneSelectionSim/GeneSelectionSim.vue";
import GeneMutationSim from "./components/GeneMutationSim/GeneMutationSim.vue";
import GeneSelectionFlowSim from "./components/GeneSelectionFlowSim/GeneSelectionFlowSim.vue";
Vue.use(Router);

export default new Router({
  routes: [
    {
      path: "/",
      name: "landing",
      component: Landing
    }, {
      path: "/drift-sim",
      name: "drift-simulation",
      component: GeneDriftSim
    }, {
      path: "/flow-sim",
      name: "flow-simulation",
      component: GeneFlowSim
    }, {
      path: "/selection-sim",
      name: "selection-simulation",
      component: GeneSelectionSim
    }, {
      path: "/mutation-sim",
      name: "mutation-simulation",
      component: GeneMutationSim
    }, {
      path: "/selection-flow-sim",
      name: "selection-flow-simulation",
      component: GeneSelectionFlowSim
    }
  ],
});
