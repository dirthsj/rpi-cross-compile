# Raspberry Pi Cross Compile
## What does this do?
This is a repository that cross compiles a sample C++ program and the boost library for various versions of the pi.

## Building for the first time
1. Ensure you have build-essential installed
    * `sudo apt-get install build-essential`
2. Run `make help` to see the available options

## How did you make this?
### Raspberry Pi Compilers
The `cross-gcc-10.2.0-pi_*.wget` files are download links from [this wonderful project](https://github.com/abhiTronix/raspberry-pi-cross-compilers) and included in this repository for convenience. If you want to swap these versions out, simply update the `PI_0_CROSS`, `PI_3_CROSS`, and/or `PI_4_CROSS` variable(s) in the Makefile.

### Boost Compiling
The `boost_1_76_0.wget` file contains the download link provided by https://www.boost.org/. You may replace it with a different 
version, however you will need to update the `BOOST_SOURCE` variable in the Makefile. I cannot guarantee the
instructions in the Makefile will work for every version of boost. If your version fails to compile for some reason,
modify the `$(BOOST_SOURCE)/b2` and `$(BOOST_INSTALL_PATH)/.touch` targets to match the instructions from the boost organization for said version.

The config file generated by `$(BOOST_INSTALL_PATH)/.touch` was created using this [documentation](https://www.boost.org/doc/libs/1_76_0/tools/build/doc/html/index.html#bbv2.overview.configuration). The command to build the b2 tool and the boost library is from [this documentation](https://www.boost.org/doc/libs/1_76_0/tools/build/doc/html/index.html#bbv2.installation).