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

    // Input & Output Definitions
    // Any Parameters (if needed, tags for samples, variables, etc)

    //input: none needed in this case, defined the command directly//

    output: 
    
    path 'hello.txt', emit: helloChannel
    // Output is stdout, so no need to define it

    // Below is the script block where any programming languages & set of instructions can be used
    // That's the beauty of Nextflow!

    // In this case, it's a simple echo statement

    script:
    """
    echo 'Hello Romania!' > hello.txt
    """

}

// Let's define a 2nd process that will convert a string to uppercase

process toUpperCase {
    input:
    path message

    output:
    path 'uppercase.txt', emit: uppercaseFile
    stdout emit: uppercaseStdout

    script:
    """
    cat $message | tr '[a-z]' '[A-Z]' | tee uppercase.txt
    """

}

// Process is defined, moving on to the workflow!

// Workflow definition

// workflow my_first_workflow {
workflow{
    
    // Process(es) & channel(s) are defined here

    // Process 1
    sayHello()
    
    // Process 2 
    toUpperCase(sayHello.out.helloChannel)

    // More processes can be defined here, as needed

    // Use the .view() method to view the results in the console
    toUpperCase.out.uppercaseFile.view { "File content: ${it.text}" }
    toUpperCase.out.uppercaseStdout.view { "Stdout content: $it" }
}