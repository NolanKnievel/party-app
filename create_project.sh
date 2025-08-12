#!/bin/bash

# Create the basic iOS project structure
mkdir -p PartyGameApp
mkdir -p PartyGameApp/Models
mkdir -p PartyGameApp/Services
mkdir -p PartyGameApp/Repositories
mkdir -p PartyGameApp/Views
mkdir -p PartyGameApp/ViewModels
mkdir -p PartyGameApp/Assets.xcassets
mkdir -p PartyGameApp/Preview\ Content
mkdir -p PartyGameAppTests
mkdir -p PartyGameAppTests/ModelTests
mkdir -p PartyGameAppTests/ServiceTests
mkdir -p PartyGameAppTests/RepositoryTests

echo "Project structure created. Please open Xcode and create a new iOS project named 'PartyGameApp' in this directory."
echo "Then add the files I've created to the project through Xcode's interface."