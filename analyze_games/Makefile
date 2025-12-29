# Makefile for analyze_games
# MAME game analyzer and config generator

# Compiler
CXX = g++

# Target executable
TARGET = analyze_games

# Source files
SRCS = analyze_games.cpp

# Compiler and linker flags
CXXFLAGS = -Wall -O2 -std=c++17
LDFLAGS = -ltinyxml2

# Default build
all: $(TARGET)

# Compile object file
%.o: %.cpp
	@echo "Compiling $<..."
	@$(CXX) $(CXXFLAGS) -c $< -o $@

# Link executable
$(TARGET): $(SRCS:.cpp=.o)
	@echo "Linking $@..."
	@$(CXX) -o $@ $^ $(LDFLAGS)
	@echo "Built: $(TARGET)"

# Clean build artifacts
clean:
	@echo "Cleaning analyze_games build artifacts..."
	@rm -f $(TARGET) *.o

.PHONY: all clean
