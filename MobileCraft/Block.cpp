//
//  Block.cpp
//  Mycraft
//
//  Created by Clapeysron on 14/11/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#include "Block.hpp"

float vertex[QUAD_SIZE/VERTEX_SIZE][QUAD_SIZE] = {
    // x-
    0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 0.1f,
    0.0f, 0.0f, 1.0f, -1.0f, 0.0f, 0.0f, 0.1f, 0.1f,
    0.0f, 1.0f, 1.0f, -1.0f, 0.0f, 0.0f, 0.1f, 0.0f,
    0.0f, 1.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 0.1f,
    0.0f, 1.0f, 1.0f, -1.0f, 0.0f, 0.0f, 0.1f, 0.0f,
    // x+
    1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.1f, 0.1f,
    1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.1f,
    1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.1f, 0.0f,
    1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.1f, 0.1f,
    1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f,
    //z-
    0.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.1f, 0.1f,
    0.0f, 1.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.1f, 0.0f,
    1.0f, 1.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f,
    1.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.1f,
    0.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.1f, 0.1f,
    1.0f, 1.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f,
    //z+
    0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.1f,
    0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.1f, 0.0f,
    1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.1f, 0.1f,
    0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.1f,
    1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.1f, 0.0f,
    //y-
    0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.1f, 0.1f,
    0.0f, 0.0f, 1.0f, 0.0f, -1.0f, 0.0f, 0.1f, 0.0f,
    1.0f, 0.0f, 1.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f,
    1.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.1f,
    0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.1f, 0.1f,
    1.0f, 0.0f, 1.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f,
    //y+
    0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.1f,
    0.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.1f, 0.0f,
    1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.1f, 0.1f,
    0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.1f,
    1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.1f, 0.0f
};

std::vector<float> Quads;

Block::Block() {
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
}

void Block::updateBuffer(bool isNew, float *vertex, unsigned long size) {
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    if(isNew) {
        glBufferData(GL_ARRAY_BUFFER, size*sizeof(float), vertex, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * sizeof(float), (void*)0);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, VERTEX_SIZE * sizeof(float), (void*)(3*sizeof(float)));
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, VERTEX_SIZE * sizeof(float), (void*)(6*sizeof(float)));
    }
    else {
        //glBufferData(GL_ARRAY_BUFFER, size*sizeof(float), vertices, GL_STATIC_DRAW);
        //glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)0);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size*sizeof(float), vertex);
        /*void * ptr = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
        memcpy(ptr, vertices, sizeof(vertices));
        glUnmapBuffer(GL_ARRAY_BUFFER);*/
    }
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glBindVertexArray(VAO);
}

Block::~Block() {
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
}

unsigned int Block::getVAO(){
    return VAO;
}
