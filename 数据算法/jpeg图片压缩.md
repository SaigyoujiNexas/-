@[TOC](JPEG图像压缩)

# 基本思想

人对图像**亮度**的感知大于**色彩**

## YCbCr

分为三部分: Y , Chroma blue, Chroma red.

其中一个思想是压缩Cb和Cr, 保留全部Y， 称为色度采样

## Frequency Component in Images

1. Real world images tend to have more low frequency components.
2. Human visual system is less sensitive to higher frequency detail.

How do we get frequency components from an image?

# Discrete Cosine Transform(DCT)

将频率曲线用余弦函数表示。

通过丢弃高频数据实现压缩

。

![image-20220520162506195](E:\学习笔记\数据算法\image-20220520162506195.png)