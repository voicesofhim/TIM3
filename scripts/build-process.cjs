#!/usr/bin/env node
// Simple build script to replace Docker-based Lua squishing
// This combines Lua files and copies them to build directory

const fs = require('fs');
const path = require('path');

function buildProcess(processDir) {
    const srcFile = path.join(processDir, 'src', 'process.lua');
    const buildFile = path.join(processDir, 'build', 'process.lua');
    
    if (!fs.existsSync(srcFile)) {
        console.error(`❌ Source file not found: ${srcFile}`);
        process.exit(1);
    }
    
    // Ensure build directory exists
    const buildDir = path.dirname(buildFile);
    if (!fs.existsSync(buildDir)) {
        fs.mkdirSync(buildDir, { recursive: true });
    }
    
    // For now, just copy the file (later we can add actual squishing)
    fs.copyFileSync(srcFile, buildFile);
    
    console.log(`✅ Built process: ${path.basename(processDir)}`);
    console.log(`   Source: ${srcFile}`);
    console.log(`   Output: ${buildFile}`);
}

// Get process directory from command line argument
const processDir = process.argv[2];
if (!processDir) {
    console.error('❌ Please provide process directory');
    console.error('Usage: node scripts/build-process.js ao/mock-usda');
    process.exit(1);
}

buildProcess(processDir);