require 'godata'
require 'cunn'
require 'cutorch'

function eval(model, inputs, targets, criterion)
    grads:zero()
    preds = model:forward(inputs)

    cost = criterion:forward(preds, targets)
    df_do = criterion:backward(preds, targets)
    model:backward(inputs, df_do)
    return cost, grads
end

function validate(model, data, labels, criterion)
    local cost, grads = eval(model, data:double(), labels:double(), criterion)
    return cost
end

function train(model, criterion, batchSize, iters, optimizer, useCuda)
    cudaInput = torch.CudaTensor()
    cudaOutput = torch.CudaTensor()
  
    useCuda = true 
    if useCuda then 
        model = model:cuda()
        criterion = criterion:cuda()
    end
    parameters, grads = model:getParameters()

    train_costs = {}

    for i = 1, iters do
        batch = ToyDataset:minibatch('toy', batchSize)

        if useCuda then
            cudaInput:resize(batch.input:size()):copy(batch.input:float())
            cudaOutput:resize(batch.output:size()):copy(batch.output:float())
            cost, grad = eval(model, cudaInput, cudaOutput, criterion)
        else
            cost, grad = eval(model, batch.input, batch.output, criterion)
        end

        if i % 10 == 0 then
            print(cost)
            table.insert(train_costs, cost)
        end
        optimizer:step(parameters, grad)
    end

    return train_costs
end
