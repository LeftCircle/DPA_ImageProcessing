CC = g++

# Update these to point to your custom include and lib directories for OpenImageIO and OpenEXR
OPEN_IMG_IO_AND_EXR_INCLUDE_PATH = /home/leftcircle/programming/include
OPEN_IMG_IO_AND_EXR_LIB_PATH = /home/leftcircle/programming/lib

CFLAGS = -Wall -g -O2 -fPIC -fopenmp -std=c++17 \
-Iinclude \
-I$(OPEN_IMG_IO_AND_EXR_INCLUDE_PATH) 

# -L/home/leftcircle/programming/lib:
#     Linker flags to find OpenImageIO and OpenEXR libs at compile time
# -Wl,-rpath,/home/leftcircle/programming/lib
#     Linker flags to find OpenImageIO and OpenEXR libs at runtime
LDFLAGS = -lOpenImageIO -lOpenImageIO_Util -lGL -lGLU -lglut \
-L$(OPEN_IMG_IO_AND_EXR_LIB_PATH) \
-Wl,-rpath,$(OPEN_IMG_IO_AND_EXR_LIB_PATH)


SRC = $(wildcard src/*.cpp)
# Filter out tests.cpp from the main build
MAIN_SRC = $(filter-out src/tests.cpp, $(SRC))
OBJDIR = obj
MAIN_OBJS = $(patsubst src/%.cpp,$(OBJDIR)/%.o,$(MAIN_SRC)) $(OBJDIR)/main.o

# Test objects - all source files except main.cpp
TEST_SRC = $(filter-out src/main.cpp, $(SRC))
TEST_OBJS = $(patsubst src/%.cpp,$(OBJDIR)/%.o,$(TEST_SRC))

TARGET = imgviewer
TEST_TARGET = test_runner

all: $(OBJDIR) $(TARGET)

$(OBJDIR):
	mkdir -p $(OBJDIR)

# Main program target
$(TARGET): $(MAIN_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: src/%.cpp
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/main.o: main.cpp
	$(CC) $(CFLAGS) -c $< -o $@

# Test target
tests: $(OBJDIR) $(TEST_TARGET)

$(TEST_TARGET): $(TEST_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

test: tests
	./$(TEST_TARGET)

clean: 
	rm -rf $(OBJDIR) $(TARGET) $(TEST_TARGET)

# ==================== SWIG Python Bindings ====================
# Python configuration - adjust for your Python version
PYTHON_VERSION = 3.12
PYTHON_INCLUDE = $(shell python$(PYTHON_VERSION)-config --includes)
PYTHON_LDFLAGS = $(shell python$(PYTHON_VERSION)-config --ldflags --embed)

SWIG = swig
SWIG_FLAGS = -c++ -python

SWIG_INTERFACE = image_editor.i
SWIG_WRAP = image_editor_wrap.cxx
SWIG_MODULE = _image_editor.so

# Source files for the shared library (exclude main.cpp and tests.cpp)
LIB_SRC = $(filter-out src/tests.cpp, $(SRC))
LIB_OBJS = $(patsubst src/%.cpp,$(OBJDIR)/%.o,$(LIB_SRC))

# Generate the SWIG wrapper
$(SWIG_WRAP): $(SWIG_INTERFACE)
	$(SWIG) $(SWIG_FLAGS) -I./include $(SWIG_INTERFACE)

# Build the Python module
$(SWIG_MODULE): $(SWIG_WRAP) $(LIB_OBJS)
	$(CC) -shared -fPIC $(CFLAGS) $(PYTHON_INCLUDE) \
		$(SWIG_WRAP) $(LIB_OBJS) \
		$(LDFLAGS) $(PYTHON_LDFLAGS) \
		-o $(SWIG_MODULE)

# Target to build Python bindings
python: $(OBJDIR) $(SWIG_MODULE)
	@echo "Python module built: $(SWIG_MODULE)"
	@echo "You can now import image_editor in Python"

clean-python:
	rm -f $(SWIG_WRAP) image_editor.py $(SWIG_MODULE) *.pyc

clean-all: clean clean-python