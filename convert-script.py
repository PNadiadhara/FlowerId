import coremltools

caffe_model = ('oxford102.caffemodel', 'deploy.prototxt')

labels = 'flower-labels.txt'

coreml_model = coremltools.converters.caffe.convert(
    caffe_model,
    class_labels=labels,
    image_input_names='data' 
)

#note 'data' comes from deploy.prototxt

coreml_model.save('FlowerClassifier.mlmodel') # .mlmodel file extention required



# $ source python27/bin/activate -> used for python enviroment on terminal