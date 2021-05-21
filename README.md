# Real-Time DDSP Timbre Transfer in MATLAB

Requires MATLAB >= R2020b and the Audio Toolbox.

This plugin is based on Google Magenta's Differentiable Digital Signal Processing (https://github.com/magenta/ddsp).

DDSP trains an autoencoder to extract pitch, loudness and timbre information from a given audio signal, and to generate synthesizer parameters from this information to reconstruct the original audio.
If the autoencoder is trained on e.g. a violin sound, we feed its decoder with pitch and loudness information from any arbitrary sound source to transform the source into a violin. This is called timbre transfer ([try the demo notebook!](https://colab.research.google.com/github/magenta/ddsp/blob/master/ddsp/colab/demos/timbre_transfer.ipynb)).

`buildPlugins.m` constructs timbre transfer plugins for the four provided examples. The weights of a flute, violin, trumpet and saxophone model were extracted from the timbre transfer demo notebook. You can also build the plugins individually, if you call `addpath('plugincode')` first.

It's also possible to [train your own network](https://colab.research.google.com/github/magenta/ddsp/blob/master/ddsp/colab/demos/train_autoencoder.ipynb) with the same architecture as the ones in the timbre transfer demo, and use the `extract_weights.py` script to turn a checkpoint into a MAT file.

To use the weight files in a MATLAB plugin, simply inherit the `plugincode/ddspPlugin` class and set the `ModelFile` property to the path of the MAT file containing the decoder weights. 

For further detail and a demonstration, refer to this video:

https://youtu.be/c_pZHzz_1bs
