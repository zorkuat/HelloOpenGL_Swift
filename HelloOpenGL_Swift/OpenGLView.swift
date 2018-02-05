//
//  OpenGLView.swift
//  HelloOpenGL_Swift
//
//  Created by DR on 8/24/15.
//  Copyright (c) 2015 DR. All rights reserved.
//
//  Based on code posted by Ray Wenderlich:
//  http://www.raywenderlich.com/3664/opengl-tutorial-for-ios-opengl-es-2-0
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

struct Vertex {
    var Position: (Float, Float, Float)
    var Color: (Float, Float, Float, Float)
}

let X = Float(0.525731112119133606)
let Z = Float(0.850650808352039932)

class OpenGLView: UIView {
    var _context: EAGLContext?
    var _colorRenderBuffer = GLuint()
    var _colorSlot = GLuint()
    var _currentRotation = Float()
    var _depthRenderBuffer = GLuint()
    var _eaglLayer: CAEAGLLayer?
    var _modelViewUniform = GLuint()
    var _positionSlot = GLuint()
    var _projectionUniform = GLuint()
    
    var _vertices = [
        Vertex(Position: ( -X, 0.0, Z), Color: (1, 0, 0, 1)),
        Vertex(Position: ( X, 0.0, Z), Color: (1, 0, 0, 1)),
        Vertex(Position: (-X, 0.0, -Z), Color: (0, 1, 0, 1)),
        Vertex(Position: (X, 0.0, -Z), Color: (0, 1, 0, 1)),
        Vertex(Position: ( 0.0, Z, X), Color: (1, 0, 0, 1)),
        Vertex(Position: ( 0.0, Z, -X), Color: (1, 0, 0, 1)),
        Vertex(Position: (0.0, -Z, X), Color: (0, 1, 0, 1)),
        Vertex(Position: (0.0, -Z, -X), Color: (0, 1, 0, 1)),
        Vertex(Position: (Z, X, 0.0), Color: (0, 1, 0, 1)),
        Vertex(Position: (-Z, X, 0.0), Color: (0, 1, 0, 1)),
        Vertex(Position: (Z, -X, 0.0), Color: (0, 1, 0, 1)),
        Vertex(Position: (-Z, -X, 0.0), Color: (0, 1, 0, 1))
        
    ]

    var _indices : [GLubyte] = [
    0,4,1,
    0,9,4,
    9,5,4,
    4,5,8,
    4,8,1,
    8,10,1,
    8,3,10,
    5,3,8,
    5,2,3,
    2,7,3,
    7,10,3,
    7,6,10,
    7,11,6,
    11,0,6,
    0,1,6,
    6,1,10,
    9,0,11,
    9,11,2,
    9,2,5,
    7,2,11
    ]

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if (self.setupLayer() != 0) {
            NSLog("OpenGLView init():  setupLayer() failed")
            return
        }
        if (self.setupContext() != 0) {
            NSLog("OpenGLView init():  setupContext() failed")
            return
        }
        if (self.setupDepthBuffer() != 0) {
            NSLog("OpenGLView init():  setupDepthBuffer() failed")
            return
        }
        if (self.setupRenderBuffer() != 0) {
            NSLog("OpenGLView init():  setupRenderBuffer() failed")
            return
        }
        if (self.setupFrameBuffer() != 0) {
            NSLog("OpenGLView init():  setupFrameBuffer() failed")
            return
        }
        if (self.compileShaders() != 0) {
            NSLog("OpenGLView init():  compileShaders() failed")
            return
        }
        if (self.setupVBOs() != 0) {
            NSLog("OpenGLView init():  setupVBOs() failed")
            return
        }
        if (self.setupDisplayLink() != 0) {
            NSLog("OpenGLView init():  setupDisplayLink() failed")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("OpenGLView init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }
    
    func compileShader(shaderName: String, shaderType: GLenum, shader: UnsafeMutablePointer<GLuint>) -> Int {
        let shaderPath = Bundle.main.path(forResource: shaderName, ofType:"glsl")
        var error : NSError?
        let shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile: shaderPath!, encoding:String.Encoding.utf8.rawValue)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if error != nil {
            NSLog("OpenGLView compileShader():  error loading shader: %@", error!.localizedDescription)
            return -1
        }
        
        shader.pointee = glCreateShader(shaderType)
        if (shader.pointee == 0) {
            NSLog("OpenGLView compileShader():  glCreateShader failed")
            return -1
        }
        var shaderStringUTF8 = shaderString!.utf8String
        var shaderStringLength: GLint = GLint(Int32(shaderString!.length))
        glShaderSource(shader.pointee, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shader.pointee);
        var success = GLint()
        glGetShaderiv(shader.pointee, GLenum(GL_COMPILE_STATUS), &success)
        
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 256)
            var infoLogLength = GLsizei()
            
            glGetShaderInfoLog(shader.pointee, GLsizei(MemoryLayout<GLchar>.size * 256), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShader():  glCompileShader() failed:  %@", String(cString: infoLog))
            
            infoLog.deallocate(capacity: 256)
            return -1
        }
        
        return 0
    }
    
    func compileShaders() -> Int {
        let vertexShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let fragmentShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let program = glCreateProgram()
        glAttachShader(program, vertexShader.pointee)
        glAttachShader(program, fragmentShader.pointee)
        glLinkProgram(program)
        
        var success = GLint()
        
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &success)
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 1024)
            var infoLogLength = GLsizei()
            
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size * 1024), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShaders():  glLinkProgram() failed:  %@", String(cString:  infoLog))
            
            infoLog.deallocate(capacity: 1024)
            fragmentShader.deallocate(capacity: 1)
            vertexShader.deallocate(capacity: 1)
            
            return -1
        }
        
        glUseProgram(program)
        
        _positionSlot = GLuint(glGetAttribLocation(program, "Position"))
        _colorSlot = GLuint(glGetAttribLocation(program, "SourceColor"))
        glEnableVertexAttribArray(_positionSlot)
        glEnableVertexAttribArray(_colorSlot)
        
        _projectionUniform = GLuint(glGetUniformLocation(program, "Projection"))
        _modelViewUniform = GLuint(glGetUniformLocation(program, "Modelview"))
        
        fragmentShader.deallocate(capacity: 1)
        vertexShader.deallocate(capacity: 1)
        return 0
    }
    
    func render(displayLink: CADisplayLink) -> Int {
        
        // FONDO
        glClearColor(0, 104.0/255.0, 55.0/255.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_DEPTH_TEST))
        
        let projection = CC3GLMatrix.matrix()
        let h : CGFloat = 4.0 * self.frame.size.height / self.frame.size.width
        (projection! as AnyObject).populate(fromFrustumLeft: GLfloat(-2), andRight: GLfloat(2), andBottom: GLfloat(-h/2), andTop: GLfloat(h/2), andNear: GLfloat(4), andFar: GLfloat(10))
        
        glUniformMatrix4fv(GLint(_projectionUniform), 1, 0, (projection! as AnyObject).glMatrix)
        
        let modelView = CC3GLMatrix.matrix()
        (modelView! as AnyObject).populate(fromTranslation: CC3VectorMake(GLfloat(0), GLfloat(0), GLfloat(-7)))
        
        // CC3VectorMake(GLfloat(sin(CACurrentMediaTime())), GLfloat(0), GLfloat(-7))
        
        //_currentRotation += Float(displayLink.duration) * Float(90)
        //(modelView! as AnyObject).rotate(by: CC3VectorMake(_currentRotation, _currentRotation, 0))
        
        glUniformMatrix4fv(GLint(_modelViewUniform), 1, 0, (modelView! as AnyObject).glMatrix)
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height));
        
        let positionSlotFirstComponent = UnsafePointer<Int>(bitPattern:0)
        glEnableVertexAttribArray(_positionSlot)
        glVertexAttribPointer(_positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), positionSlotFirstComponent)
        
        glEnableVertexAttribArray(_colorSlot)
        let colorSlotFirstComponent = UnsafePointer<Int>(bitPattern:MemoryLayout<Float>.size * 3)
        glVertexAttribPointer(_colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), colorSlotFirstComponent)
        
        let vertexBufferOffset = UnsafeMutableRawPointer(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((_indices.count * MemoryLayout<GLubyte>.size)/MemoryLayout<GLubyte>.size),
                       GLenum(GL_UNSIGNED_BYTE), vertexBufferOffset)
        
        _context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        return 0
    }
    
    func setupContext() -> Int {
        let api : EAGLRenderingAPI = EAGLRenderingAPI.openGLES2
        _context = EAGLContext(api: api)
        
        if (_context == nil) {
            NSLog("Failed to initialize OpenGLES 2.0 context")
            return -1
        }
        if (!EAGLContext.setCurrent(_context)) {
            NSLog("Failed to set current OpenGL context")
            return -1
        }
        return 0
    }
    
    func setupDepthBuffer() -> Int {
        glGenRenderbuffers(1, &_depthRenderBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        return 0
    }
    
    func setupDisplayLink() -> Int {
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(OpenGLView.render(displayLink:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.defaultRunLoopMode.rawValue))
        return 0
    }
    
    func setupFrameBuffer() -> Int {
        var framebuffer: GLuint = 0
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0),
                                  GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        return 0
    }
    
    func setupLayer() -> Int {
        _eaglLayer = self.layer as? CAEAGLLayer
        if (_eaglLayer == nil) {
            NSLog("setupLayer:  _eaglLayer is nil")
            return -1
        }
        _eaglLayer!.isOpaque = true
        return 0
    }
    
    func setupRenderBuffer() -> Int {
        glGenRenderbuffers(1, &_colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        
        if (_context == nil) {
            NSLog("setupRenderBuffer():  _context is nil")
            return -1
        }
        if (_eaglLayer == nil) {
            NSLog("setupRenderBuffer():  _eagLayer is nil")
            return -1
        }
        if (_context!.renderbufferStorage(Int(GL_RENDERBUFFER), from: _eaglLayer!) == false) {
            NSLog("setupRenderBuffer():  renderbufferStorage() failed")
            return -1
        }
        return 0
    }
    
    func setupVBOs() -> Int {
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (_vertices.count * MemoryLayout<Vertex>.size), _vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (_indices.count * MemoryLayout<GLubyte>.size), _indices, GLenum(GL_STATIC_DRAW))
        return 0
    }
    
}
