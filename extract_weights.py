# Script to export the weights of a trained DDSP autoencoder to a MAT file
# requires DDSP >= 1.1.0 and scipy

# This is written for the specific architecture of the models used in the Timbre Transfer Demo
# https://colab.research.google.com/github/magenta/ddsp/blob/master/ddsp/colab/demos/timbre_transfer.ipynb

import ddsp.training.inference as inference
import scipy

# change these to the directory containing the checkpoint of the trained DDSP model
# and the name of the generated MAT file
CHECKPOINTDIR = './CHANGEME'
OUTPUTFILE    = 'CHANGEME.mat'


model = inference.AutoencoderInference(CHECKPOINTDIR)

weights = model.decoder.trainable_weights
weight_dict = {}
for i in range(3):
    weight_dict[f'ld_dense_{i}_kernel'] = weights[2+i*4].numpy()
    weight_dict[f'ld_dense_{i}_bias']   = weights[2+i*4+1].numpy()
    weight_dict[f'ld_norm_{i}_gamma']   = weights[2+i*4+2].numpy()
    weight_dict[f'ld_norm_{i}_beta']    = weights[2+i*4+3].numpy()
    
    weight_dict[f'f0_dense_{i}_kernel'] = weights[2+4*3+i*4].numpy()
    weight_dict[f'f0_dense_{i}_bias']   = weights[2+4*3+i*4+1].numpy()
    weight_dict[f'f0_norm_{i}_gamma']   = weights[2+4*3+i*4+2].numpy()
    weight_dict[f'f0_norm_{i}_beta']    = weights[2+4*3+i*4+3].numpy()
    
    weight_dict[f'out_dense_{i}_kernel'] = weights[2+4*6+3+i*4].numpy()
    weight_dict[f'out_dense_{i}_bias']   = weights[2+4*6+3+i*4+1].numpy()
    weight_dict[f'out_norm_{i}_gamma']   = weights[2+4*6+3+i*4+2].numpy()
    weight_dict[f'out_norm_{i}_beta']    = weights[2+4*6+3+i*4+3].numpy()

weight_dict['outsplit_kernel'] = weights[0].numpy()
weight_dict['outsplit_bias']   = weights[1].numpy() 

weight_dict['gru_kernel']    = weights[2+4*6].numpy()
weight_dict['gru_recurrent'] = weights[2+4*6+1].numpy()
weight_dict['gru_bias']      = weights[2+4*6+2].numpy()
    
scipy.io.savemat(OUTPUTFILE, weight_dict)
