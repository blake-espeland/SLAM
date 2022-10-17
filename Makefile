# set GPU [ON or OFF] in CMakeLists.txt -> denotes using/not using GPU


all: 
	@echo "-------------------[ Building Target ]-------------------"
	@cmake --build build --parallel `nproc` 
	@cd build && make
	@mv ./build/SLAM .