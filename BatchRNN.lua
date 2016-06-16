------------------------------------------------------------------------
--[[ BatchRNN ]] --
-- Adds sequence-wise batch normalization to cudnn RNN modules.
-- For a simple RNN: ht = ReLU(B(Wixt) + Riht-1 + bRi) where B
-- is the batch normalization.
-- Expects size seqLength x minibatch x inputDim.
-- Returns seqLength x minibatch x outputDim.
-- Can specify an rnnModule such as cudnn.LSTM (defaults to RNNReLU).
------------------------------------------------------------------------
local BatchRNN, parent = torch.class('cudnn.BatchRNN', 'nn.Sequential')

function BatchRNN:__init(inputDim, outputDim)
    parent.__init(self)

    self.view_in = nn.View(1, 1, -1):setNumInputDims(3)
    self.view_out = nn.View(1, -1):setNumInputDims(2)

    self.rnn = cudnn.RNN(outputDim, outputDim, 1)
    local rnn = self.rnn
    rnn.inputMode = 'CUDNN_SKIP_INPUT'
    rnn:reset()

    self:add(self.view_in)
    self:add(nn.Linear(inputDim, outputDim, false))
    self:add(nn.BatchNormalization(outputDim))
    self:add(self.view_out)
    self:add(rnn)
end

function BatchRNN:updateOutput(input)
    local T, N = input:size(1), input:size(2)
    self.view_in:resetSize(T * N, -1)
    self.view_out:resetSize(T, N, -1)
    return parent.updateOutput(self, input)
end

function BatchRNN:__tostring__()
    if self.module.__tostring__ then
        return torch.type(self) .. ' @ ' .. self.module:__tostring__()
    else
        return torch.type(self) .. ' @ ' .. torch.type(self.module)
    end
end