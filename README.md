# PODsys
## What is PODsys?


PODsys focuses on AI cluster deployment scenarios, providing a complete toolchain including
        infrastructure environment installation, environment deployment, user management, system
        monitoring and resource scheduling, aiming to create an open-source, efficient, compatible and
        easy-to-use intelligent cluster system environment deployment solution.

To achieve these capabilities, PODsys integrates dozens of drivers, softwares, and other
        installation packages required for AI cluster deployment, and provides a range of scripting
        tools to simplify deployment. Using these tools, users can complete the deployment of the entire
        cluster with several simple commands.

- **Environment deployment and management:** PODsys provides quick tools for environment deployment
          and management, including quick installation, configuration, and updating of cluster environments.
          It also includes the operating system, NVIDIA drivers, InfiniBand drivers and other necessary
          software base packages, to provide users with a complete GPU cluster environment. Users can
          manage cluster nodes, add or remove nodes, and monitor node status and performance with simple commands.

- **User management and permission control:** PODsys has a comprehensive user management and permission
          control mechanism. Administrators can create and manage user accounts and assign different permissions
          and resource quotas. This allows each user or team to flexibly allocate resources in the cluster
          and ensures the security of the cluster.

- **System monitoring and performance optimization:** PODsys provides comprehensive system monitoring
          and performance optimization capabilities to help users monitor the status and performance indicators
          of the cluster in real time. Through a visual interface, users can view cluster resource usage,
          job execution, and performance bottlenecks to adjust cluster configurations and optimize job
          performance in a timely manner.

## Quick Start

For the full package download, please visit https://podsys.ai/.

Download from Hugging Face [PODsys](https://huggingface.co/podsysai/PODsys/tree/main)

Download from Baidu Netdisk [PODsys](https://pan.baidu.com/s/1YlisXhSGGWVZv-vexuFGxg?pwd=0zq9)

| Component               | Version                 |
|------------------------|---------------------|
| OS                               | Ubuntu Server 22.04.4 LTS     |
| Linux kernel              | 5.15.0-94-generic            |
| NVIDIA GPU Driver  | 535.161.08                       |
| CUDA Toolkit             | 12.2.2                              |
| NCCL                          | 2.20.3                             |
| cuDNN                       | 9.0.0                                |
| DCGM                        | 3.3.5                                 |
| Docker Engine          | 26.1.1                               |
| NVIDIA Container Toolkit | 1.14.6                           |
| InfiniBand Driver       | MLNX_OFED_LINUX-23.10-2.1.3.1 |
| PDSH                        | 2.31 (+debug)                   |
