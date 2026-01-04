# Makefile for analyze_games
# MAME game analyzer and config generator

# Compiler
CXX = g++

# Target executables
TARGETS = analyze_games analyze_controls list_controls

# Source files
SRCS_ANALYZE_GAMES = analyze_games.cpp
SRCS_ANALYZE_CONTROLS = analyze_controls.cpp
SRCS_LIST_CONTROLS = list_controls.cpp

# Compiler and linker flags
CXXFLAGS = -Wall -O2 -std=c++17
LDFLAGS = -ltinyxml2

# Default build
all: $(TARGETS)

# Compile object file
%.o: %.cpp
	@echo "Compiling $<..."
	@$(CXX) $(CXXFLAGS) -c $< -o $@

# Link analyze_games executable
analyze_games: analyze_games.o
	@echo "Linking $@..."
	@$(CXX) -o $@ $^ $(LDFLAGS)
	@echo "Built: $@"

# Link analyze_controls executable
analyze_controls: analyze_controls.o
	@echo "Linking $@..."
	@$(CXX) -o $@ $^ $(LDFLAGS)
	@echo "Built: $@"

# Link list_controls executable
list_controls: list_controls.o
	@echo "Linking $@..."
	@$(CXX) -o $@ $^ $(LDFLAGS)
	@echo "Built: $@"

# Clean build artifacts
clean:
	@echo "Cleaning analyze_games and analyze_controls build artifacts..."
	@rm -f $(TARGETS) *.o

.PHONY: all clean
