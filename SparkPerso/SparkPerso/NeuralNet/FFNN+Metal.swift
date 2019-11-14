//
//  FFNN+Metal.swift
//  ImageDatasGetter
//
//  Created by alban perli on 24.02.17.
//  Copyright © 2017 alban perli. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import QuartzCore

class FFNNMetal {
    var device: MTLDevice? = nil
    var commandQueue: MTLCommandQueue?
    var metalNNLibrary: MTLLibrary?
    var computeCommandEncoder:MTLComputeCommandEncoder?
    var commandBuffer: MTLCommandBuffer?
    var computePipelineFilterSigmoid:MTLComputePipelineState?
    var computePipelineFilterUpdatedHidden:MTLComputePipelineState?
    
    static let instance = FFNNMetal()
    
    init() {
        setupMetal()
    }
    
    func setupMetal() {
        /*
        // Get access to GPU
        self.device = MTLCreateSystemDefaultDevice()
        
        // Queue to handle an ordered list of command buffers
        self.commandQueue = device!.makeCommandQueue()
        
        // Buffer for storing encoded commands that are sent to GPU
        //commandBuffer = commandQueue?.makeCommandBuffer()
        
        // Encoder for GPU commands
        //self.computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        // Access to Metal functions that are stored in MetalNeuralNetworkShaders string, e.g. sigmoid()
        //self.metalNNLibrary = try? device!.makeLibrary(source: metalNNShaders, options: nil)
        
        if let defaultLib = device?.newDefaultLibrary(){
            //let sigmoidProgram = defaultLib.makeFunction(name: "sigmoid")
            //computePipelineFilterSigmoid = try! device?.makeComputePipelineState(function:sigmoidProgram!)
            let updatedHiddenWeightProgramm = defaultLib.makeFunction(name: "updateSwiftAIWeights")
            computePipelineFilterUpdatedHidden = try! device?.makeComputePipelineState(function:updatedHiddenWeightProgramm!)
        }
        
        
        */
    }
    
    func sigmoidOnArray(myvector:[Float])  {
        /*
        // a. calculate byte length of input data - myvector
        let myvectorByteLength = myvector.count*MemoryLayout.size(ofValue: myvector[0])
        
        // b. create a MTLBuffer - input data that the GPU and Metal and produce
        let inVectorBuffer = device?.makeBuffer(bytes: UnsafeRawPointer(myvector), length: myvectorByteLength)
        
        // c. set the input vector for the Sigmoid() function, e.g. inVector
        //    atIndex: 0 here corresponds to buffer(0) in the Sigmoid function
        computeCommandEncoder?.setBuffer(inVectorBuffer, offset: 0, at: 0)
        
        // d. create the output vector for the Sigmoid() function, e.g. outVector
        //    atIndex: 1 here corresponds to buffer(1) in the Sigmoid function
        let resultdata = [Float](repeating: 0, count:myvector.count)
        let outVectorBuffer = device?.makeBuffer(bytes: UnsafeMutableRawPointer(mutating: resultdata), length: myvectorByteLength)
        self.computeCommandEncoder?.setBuffer(outVectorBuffer, offset: 0, at: 1)
        
        
        self.computeCommandEncoder?.setComputePipelineState(computePipelineFilterSigmoid!)
        
        // hardcoded to 32 for now (recommendation: read about threadExecutionWidth)
        var threadsPerGroup = MTLSize(width:32,height:1,depth:1)
        var numThreadgroups = MTLSize(width:(myvector.count+31)/32, height:1, depth:1)
        computeCommandEncoder?.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        
        computeCommandEncoder?.endEncoding()
        self.commandBuffer?.commit()
        self.commandBuffer?.waitUntilCompleted()
        
        var data = NSData(bytesNoCopy: (outVectorBuffer?.contents())!,
                          length: myvector.count*MemoryLayout<Float>.size, freeWhenDone: false)
        // b. prepare Swift array large enough to receive data from GPU
        var finalResultArray = [Float](repeating: 0, count: myvector.count)
        
        // c. get data from GPU into Swift array
        data.getBytes(&finalResultArray, length:myvector.count * MemoryLayout<Float>.size)
        
        print(finalResultArray)
        */
    }
    
    func generateArrayBuffers(inputArrays:[Float],memoryLayoutSize:Int) -> MTLBuffer {
        
        // a. calculate byte length of input data - myvector
        let myvectorByteLength = inputArrays.count*memoryLayoutSize
        
        // b. create a MTLBuffer - input data that the GPU and Metal and produce
        let inVectorBuffer = device?.makeBuffer(bytes: UnsafeRawPointer(inputArrays), length: myvectorByteLength)
        
        return inVectorBuffer!
    }
    
    func generateIntArrayBuffers(inputArrays:[Int],memoryLayoutSize:Int) -> MTLBuffer {
        
        /*
         var pointer: UnsafeMutableRawPointer? = nil
         let alignment: Int = 0x4
         let xvectorByteSize:Int = Int(Int(inputArrays.count)*Int(MemoryLayout.size(ofValue:(Int(0)))))
         
         let ret = posix_memalign(&pointer, alignment, xvectorByteSize)
         
         
         var xvectorVoidPtr = OpaquePointer(pointer)
         var xvectorFloatPtr = UnsafeMutablePointer<Int>(xvectorVoidPtr)
         var xvectorFloatBufferPtr = UnsafeMutableBufferPointer(start: xvectorFloatPtr, count: inputArrays.count)
         
         
         
         // fill xvector with data
         for index in xvectorFloatBufferPtr.startIndex..<xvectorFloatBufferPtr.endIndex {
         xvectorFloatBufferPtr[index] = Float(Index)
         }
         */
        
        
        // a. calculate byte length of input data - myvector
        let myvectorByteLength = inputArrays.count*memoryLayoutSize
        
        // b. create a MTLBuffer - input data that the GPU and Metal and produce
        let inVectorBuffer = device?.makeBuffer(bytes: UnsafeRawPointer(inputArrays), length: myvectorByteLength)
        
        return inVectorBuffer!
    }
    
    
    
    
    
    func appendBufferToCommandEncoder(buffers:[MTLBuffer]) {
        
        for i in 0..<buffers.count {
            
            //computeCommandEncoder?.setBuffer(buffers[i], offset: 0, at: i)
        }
    }
    
    func updateHiddenWeight(hiddenWeights:[Float],
                            previousHiddenWeights:[Float],
                            hiddenErrorIndices:[Int],
                            inputIndices:[Int],
                            inputCache:[Float],
                            mfLR:Float,
                            momentumFactor:Float,
                            hiddenOutputCache:[Float],
                            hiddenErrorsCache:[Float],
                            newHiddenWeights: inout [Float]) {
        
        //BenchmarkTimer.start(label: "updateHiddenWeight")
        
        
        autoreleasepool {
            
            
            
            commandBuffer = commandQueue?.makeCommandBuffer()
            self.computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
            self.computeCommandEncoder?.setComputePipelineState(computePipelineFilterUpdatedHidden!)
            
            var buffers = [MTLBuffer]()
            
            buffers.append(generateArrayBuffers(inputArrays: hiddenWeights, memoryLayoutSize: MemoryLayout.size(ofValue: hiddenWeights[0])))
            buffers.append(generateArrayBuffers(inputArrays: previousHiddenWeights, memoryLayoutSize: MemoryLayout.size(ofValue: previousHiddenWeights[0])))
            buffers.append(generateIntArrayBuffers(inputArrays: hiddenErrorIndices, memoryLayoutSize: MemoryLayout.size(ofValue: hiddenErrorIndices[0])))
            buffers.append(generateIntArrayBuffers(inputArrays: inputIndices, memoryLayoutSize: MemoryLayout.size(ofValue: inputIndices[0])))
            
            buffers.append(generateArrayBuffers(inputArrays: inputCache, memoryLayoutSize: MemoryLayout.size(ofValue: inputCache[0])))
            buffers.append(generateArrayBuffers(inputArrays: [mfLR], memoryLayoutSize: MemoryLayout.size(ofValue: mfLR)))
            buffers.append(generateArrayBuffers(inputArrays: [momentumFactor], memoryLayoutSize: MemoryLayout.size(ofValue: momentumFactor)))
            buffers.append(generateArrayBuffers(inputArrays: hiddenOutputCache, memoryLayoutSize: MemoryLayout.size(ofValue: hiddenOutputCache[0])))
            buffers.append(generateArrayBuffers(inputArrays: hiddenErrorsCache, memoryLayoutSize: MemoryLayout.size(ofValue: hiddenErrorsCache[0])))
            
            
            let newOutputWeightsLength = hiddenWeights.count*MemoryLayout.size(ofValue: hiddenWeights[0])
            var outVectorBuffer = device?.makeBuffer(bytes: UnsafeRawPointer(newHiddenWeights), length: newOutputWeightsLength)
            buffers.append(outVectorBuffer!)
            
            appendBufferToCommandEncoder(buffers: buffers)
            
            buffers = [MTLBuffer]()
            
            let threadsPerGroup = MTLSize(width:32,height:1,depth:1)
            let numThreadgroups = MTLSize(width:(hiddenWeights.count-1)/32, height:1, depth:1)
            
            computeCommandEncoder?.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
            
            computeCommandEncoder?.endEncoding()
            self.commandBuffer?.commit()
            self.commandBuffer?.waitUntilCompleted()
            commandBuffer = nil
            
            
            var data = NSData(bytesNoCopy: (outVectorBuffer?.contents())!,
                              length: newHiddenWeights.count*MemoryLayout<Float>.size, freeWhenDone: false)
            // b. prepare Swift array large enough to receive data from GPU
            //var finalResultArray = [Float](repeating: 0, count: newOutputWeights.count)
            
            // c. get data from GPU into Swift array
            data.getBytes(&newHiddenWeights, length:newHiddenWeights.count * MemoryLayout<Float>.size)
            
            data = NSData()
            outVectorBuffer = nil
            
        }
        //BenchmarkTimer.stop()
        
        //return newOutputWeights
    }
    
    
}
