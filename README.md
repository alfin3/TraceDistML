## tracedistml

The need for decreasing latencies in applications and processing large amounts of data, in some cases locally, drives the design and adoption of distributed approaches to machine learning. Two common considerations are: i) which parts of a computation to distribute and reduce, and ii) how to minimize communication latencies between nodes.

**These considerations pose an optimization problem in the “infrastructure vs. model architecture” search space.** 

To traverse this search space, we need to:
1) quickly iterate across infrastructures and model architectures, and
2) measure the “fit” between an infrastructure and a model architecture.

Towards this goal, as an Insight Fellow, I developed: 
1) a one-step provisioning of an on-premises capable k8s infrastructure to streamline infrastructure experimentation, and
2) a higher-order functional approach to enable code simplicity and research flexibility in choosing the granularity of OpenTracing instrumentation for measuring latencies of model construction. Potential use cases of this approach include optimization of real-time systems that require output “freshness” and rapid A/B testing, such as real-time recommendation systems.

## tracedistml/infrastructure

An example of infrastructure provisioning:

![infra_example](https://github.com/alfin3/tracedistml/blob/master/images/infra_image.jpg)

see further instructions in tracedistml/infrastructure.

## tracedistml/tracing-ml

An example of OpenTracing instrumentation to measure latencies of model construction with a LightStep tracer:

![latencies_explorer](https://github.com/alfin3/tracedistml/blob/master/images/latencies_explorer.jpg)

see further instructions in tracedistml/{cpu, gpu}-build-jobs.
