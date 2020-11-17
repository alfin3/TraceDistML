## infrastructure-as-opt

The need for faster processing of large amounts of data, in some cases with a notion of locality, drives the design of distributed approaches to machine learning. Two common considerations are: i) which parts of a computation to distribute and reduce/synchronize, and ii) how to minimize communication latencies.

**These considerations pose an optimization problem in the “infrastructure vs. model architecture” search space.** 

To effectively traverse this search space, it is necessary to:
1) iterate across infrastructures and model architectures, and
2) measure the “fit” between an infrastructure and a model architecture.

Towards this goal, as an Insight Fellow, I developed: 
1) a one-step provisioning of an on-premises capable k8s infrastructure to streamline infrastructure iteration, and
2) a set of proof-of-concept modules for constructing objective functions based on latency tracing

## infrastructure-as-opt/infrastructure

![infra_example](https://github.com/alfin3/tracedistml/blob/master/images/infra_image.jpg)

see further instructions in infrastructure-as-opt/infrastructure.

## infrastructure-as-opt/tracing-ml

![latencies_explorer](https://github.com/alfin3/tracedistml/blob/master/images/latencies_explorer.jpg)

see further instructions in infrastructure-as-opt/{cpu, gpu}-build-jobs.
