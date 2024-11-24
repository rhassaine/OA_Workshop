#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Infamous hello world example

// This is an example script to show how Nextflow works

// It's a simple script that:
// 1) Saves the 'Hello Romania!'string to a txt file
// 2) Converts the string to uppercase
// 3) Outputs the uppercase string to the console

// Nextflow is a powerful tool that can be used to run complex workflows
// Many processes using various inputs, outputs, and dependencies can communicate w/ each other
// in a seamless and parallelized manner, making efficient use of compute resources

// Process definition

process sayHello {
    container 'ubuntu:latest' // remove that when running in ubuntu instance
    // publishDir "${params.outdir}/hello", mode: 'copy'

    // Input & Output Definitions
    // Any Parameters (if needed, tags for samples, variables, etc)

    // input: none needed in this case, defined the command directly

    output: 
    stdout
    path 'hello.txt', emit: helloFile

    // Below is the script block where any programming languages & set of instructions can be used
    // That's the beauty of Nextflow!

    // In this case, it's a simple echo statement

    script:
    """
    echo 'Hello World!' > hello.txt
    cat hello.txt
    """

}

// Let's define a 2nd process that will convert a string to uppercase

process toUpperCase {
    container 'ubuntu:latest' // remove that when running in ubuntu instance
    // publishDir "${params.outdir}/uppercase", mode: 'copy'

    input:
    path inputFile

    output:
    path 'uppercase.txt', emit: uppercaseFile
    stdout emit: uppercaseStdout

    script:
    """
    cat ${inputFile} | tr '[a-z]' '[A-Z]' | tee uppercase.txt
    """
}

// Process is defined, moving on to the workflow!

// Workflow definition

// workflow my_first_workflow
workflow {
    // Process 1
    sayHello()

    // Process 2
    toUpperCase(sayHello.out.helloFile)

    // View the outputs
    sayHello.out.helloFile.view { "File content: ${it.text}" }
    // toUpperCase.out.uppercaseFile.view { "Uppercase file content: ${it.text}" }
    toUpperCase.out.uppercaseStdout.view { "Uppercase stdout content: $it" }
}