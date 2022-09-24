all: 
	@echo "-------------------[ Building Target ]-------------------"
	@cmake --build build --parallel `nproc`
	@cd build && make
	@mv ./build/cVIT .