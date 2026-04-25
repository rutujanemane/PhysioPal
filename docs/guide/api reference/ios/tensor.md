Tensor
Complete API reference for the Tensor class on iOS.

This page reflects ZeticMLange iOS 1.6.0.

The Tensor class is the unified data container passed to and returned from ZeticMLangeModel.run(inputs:). It wraps raw Data, its DataType, and its shape.

Import

import ZeticMLange
Initializer
Tensor(data:dataType:shape:)
Creates a tensor from raw bytes, an element type, and a shape.


public init(data: Data, dataType: any DataType, shape: [Int])
Parameter	Type	Description
data	Data	Raw tensor bytes. Length must equal the product of shape dimensions times dataType.size.
dataType	any DataType	Element type. Use a case from BuiltinDataType such as .float32.
shape	[Int]	Tensor shape.

let bytes = Data(count: 1 * 3 * 640 * 640 * MemoryLayout<Float>.size)
let tensor = Tensor(
    data: bytes,
    dataType: BuiltinDataType.float32,
    shape: [1, 3, 640, 640]
)
Tensor(data:)
Creates a tensor from raw bytes with defaults of BuiltinDataType.int8 and shape = [data.count].


public convenience init(data: Data)
Parameter	Type	Description
data	Data	Raw bytes. Interpreted as a 1-D int8 tensor whose length matches data.count.

let tensor = Tensor(data: rawBytes)
Methods
count()
Returns the number of elements in the tensor (total bytes divided by dataType.size).


public func count() -> Int
size()
Returns the size of the tensor in bytes (equivalent to data.count).


public func size() -> Int
DataType
DataType is a protocol that exposes the byte size of a tensor element.


public protocol DataType {
    var size: Int { get }
}
BuiltinDataType
The standard element types supported by Melange. Each case conforms to DataType and reports its byte size through size.


public enum BuiltinDataType: String, DataType, CaseIterable {
    case float32
    case float64
    case float16
    case bfloat16
    case uint8
    case uint16
    case uint32
    case uint64
    case int8
    case int16
    case int32
    case int64
    case boolean
    case qint8
    case qint16
    case qint32
    case qint4
}
Case	Element size (bytes)
.float32	4
.float64	8
.float16, .bfloat16	2
.uint8, .int8, .qint8	1
.uint16, .int16, .qint16	2
.uint32, .int32, .qint32	4
.uint64, .int64	8
.boolean	1
.qint4	1
Unknown
Fallback DataType returned when a type name is not recognized. Caller supplies the element size.


public struct Unknown: DataType {
    public let size: Int
}
dataType(from:)
Resolves a DataType from its lowercase string name (for example "float32" or "int8"). Unknown names return Unknown(size: 0).


public func dataType(from string: String) -> DataType

let type = dataType(from: "float32") // BuiltinDataType.float32
Properties
data
The underlying raw bytes of the tensor.


public let data: Data
dataType
The element type of the tensor.


public let dataType: any DataType
shape
The shape of the tensor.


public let shape: [Int]
Equatable
Two tensors are equal if their data and shape match.


public static func == (lhs: Tensor, rhs: Tensor) -> Bool
Full Working Example

import ZeticMLange
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let model = try ZeticMLangeModel(
                personalKey: PERSONAL_KEY,
                name: "Steve/YOLOv11_comparison"
            )
            // (1) Build an input tensor from preprocessed pixel bytes
            let pixels: [Float] = preparePixels()
            let data = pixels.withUnsafeBufferPointer { Data(buffer: $0) }
            let input = Tensor(
                data: data,
                dataType: BuiltinDataType.float32,
                shape: [1, 3, 640, 640]
            )
            // (2) Run inference
            let outputs = try model.run(inputs: [input])
            // (3) Read outputs as a typed array of Floats
            let output = outputs[0]
            let floatCount = output.count()
            let floats: [Float] = output.data.withUnsafeBytes { raw in
                Array(raw.bindMemory(to: Float.self).prefix(floatCount))
            }
        } catch {
            print("Melange error: \(error)")
        }
    }
}
The data length must equal the product of shape times dataType.size. A mismatch will cause run(inputs:) to fail at the model boundary.

Zero-copy path is not yet available on iOS. Each call to run(inputs:) copies the input Tensor's bytes into the model's internal input buffer. ZeticMLangeModel on iOS does not currently expose model-owned input buffers, so this per-inference copy cannot be avoided today. An equivalent of Android's getInputBuffers() + run() idiom is planned for a future SDK release.

