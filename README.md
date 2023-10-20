# Neural Adaptive MPC with Evolutionary-Based Tuning for Power Management in Fuel Cell Hybrid Electric Vehicles

## Description ##

This repository collects the code implementing a *neural-networks-based adaptive MPC controller* for fuel cell hybrid electric vehicles (FCHEVs) power management.
Power management consists in efficiently split the battery and fuel cell power, ensuring that the net delivered power meets the total power requested by the vehicle.

The proposed MPC scheme features:
* An optimal tuning algorithm for the MPC cost function weights, based on Particle Swarm Optimization (PSO), allowing to achieve multiple control objectives at once (such as, e.g., accurate requested power tracking and minimum supplies consumption);
* An adaptive and data-driven MPC prediction model, based on feedforward neural networks (FNNs), that approximates the real plant through input-output plant measurements;
* An alternative controller, based on FNNs, that accurately emulates the optimal control law of the original MPC controller.

The adaptive nature of the proposed MPC controller is two-fold. First, the cost function weights are adapted based on the given control objectives. Second, the MPC prediction model equations adapt over time, according to the operating conditions of the plant.

Moreover, the NN-based controller can be employed in place of the original controller, without any pauperization of the performance, and requires a significantly lower computation time with respect to basic MPC. This allows for a much easier real-time implementation on automotive control units.

<img src="https://github.com/lorenzocalogero/Neural_Adaptive_MPC_Power_Management_FCHEV/assets/49368313/054585d4-1ab1-45ee-bfcb-25e6e7cfcf03" alt="drawing" height="260"/>

<img src="https://github.com/lorenzocalogero/Neural_Adaptive_MPC_Power_Management_FCHEV/assets/49368313/a96fea44-09d2-451e-952c-d63ef63a5269" alt="drawing" height="260"/>

<img src="https://github.com/lorenzocalogero/Neural_Adaptive_MPC_Power_Management_FCHEV/assets/49368313/fdd4205c-60d9-43c0-bbb8-31b93f5bbff4" alt="drawing" height="260"/>

<img src="https://github.com/lorenzocalogero/Neural_Adaptive_MPC_Power_Management_FCHEV/assets/49368313/2fae8876-d4a4-4d7e-88c2-b74b99c710c8" alt="drawing" height="260"/>

## Prerequisites ##

For running the code, it is required to install the third-party toolbox "YALMIP", available [here](https://yalmip.github.io/ "YALMIP").

## References ##

The code is based on the following work:

* L. Calogero *et al.*, "Neural Adaptive MPC with Evolutionary-Based Tuning for Power Management in Fuel Cell Hybrid Electric Vehicles," 2023 [Under review].
