//internal includes
#include "common.h"
#include "ShaderProgram.h"
#include "LiteMath.h"

//External dependencies
#define GLFW_DLL
#include <GLFW/glfw3.h>
#include <random>

static GLsizei WIDTH = 512, HEIGHT = 512; //размеры окна

using namespace LiteMath;


void windowResize(GLFWwindow* window, int width, int height)
{
  WIDTH  = width;
  HEIGHT = height;
}



int initGL()
{
	int res = 0;
	//грузим функции opengl через glad
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		std::cout << "Failed to initialize OpenGL context" << std::endl;
		return -1;
	}

	std::cout << "Vendor: "   << glGetString(GL_VENDOR) << std::endl;
	std::cout << "Renderer: " << glGetString(GL_RENDERER) << std::endl;
	std::cout << "Version: "  << glGetString(GL_VERSION) << std::endl;
	std::cout << "GLSL: "     << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;

	return 0;
}

int main(int argc, char** argv)
{
  /* glfwInit инициализирует библиотеку GLFW. Перед использованием большинства функций GLFW необходимо инициализировать GLFW,
   а перед завершением работы приложения необходимо завершить GLFW, чтобы освободить ресурсы, выделенные во время или после инициализации. */
	if(!glfwInit())
    return -1;

	//запрашиваем контекст opengl версии 3.3
//делаем начальные настройки Л.
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3); 
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3); 
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); 
	glfwWindowHint(GLFW_RESIZABLE, GL_TRUE); 

  GLFWwindow*  window = glfwCreateWindow(WIDTH, HEIGHT, "OpenGL ray marching sample", nullptr, nullptr);//Эта функция создает окно и связанный с ним контекст OpenGL или OpenGL ES. Большинство параметров, управляющих созданием окна и его контекста, задаются с помощью подсказок окна(window hints). Л.
	if (window == nullptr)
	{
		std::cout << "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;
	}

  glfwSetWindowSizeCallback(window, windowResize);  //??????????????????????????????????????????????????????

/* Л. glfwMakeContextCurrent делает контекст OpenGL или OpenGL ES указанного окна текущим в вызывающем потоке. 
Контекст можно сделать текущим только в одном потоке за один раз, и каждый поток может иметь только один текущий контекст за один раз. ???????????????????????????????????????????*/
	glfwMakeContextCurrent(window); 



//функция, см. выше Л.
	if(initGL() != 0) 
		return -1;
	
  //Reset any OpenGL errors which could be present for some reason
	GLenum gl_error = glGetError();
	while (gl_error != GL_NO_ERROR)
		gl_error = glGetError();

	//создание шейдерной программы из двух файлов с исходниками шейдеров
	//используется класс-обертка ShaderProgram
	std::unordered_map<GLenum, std::string> shaders;
	shaders[GL_VERTEX_SHADER]   = "vertex.glsl";
	shaders[GL_FRAGMENT_SHADER] = "fragment.glsl";
	ShaderProgram program(shaders); GL_CHECK_ERRORS;


// Л. glfwSwapInterval устанавливает интервал подкачки для текущего контекста OpenGL или OpenGL ES,
// т. е. количество обновлений экрана, ожидающих с момента вызова glfwSwapBuffers до подкачки буферов и возврата.
  glfwSwapInterval(1); // force 60 frames per second
  
  //Создаем и загружаем геометрию поверхности 
//Создание переменной для хранения идентификатора VBO(см.далее)
  GLuint g_vertexBufferObject;
//Создание переменной для хранения идентификатора VAO(см.далее)
  GLuint g_vertexArrayObject;

  {
    //вершины квадрата????
    float quadPos[] =
    {
      -0.5f,  -0.5f, 0.0f,	// v0 - top left corner
      0.5f, -0.5f, 0.0f,	// v1 - bottom left corner
      0.0f,  0.5f, 0.0f	// v2 - top right corner

    };

    g_vertexBufferObject = 0;
    GLuint vertexLocation = 0; // simple layout, assume have only positions at location = 0


    /*Л. везде дальше GL_CHECK_ERRORS - полезный макрос для проверки ошибок в строчке, где он был записан  */


/*Л.   Следующие три строки работаем с Vertex Buffer Object (VBO) —  средством OpenGL, позволяющее загружать определенные данные в память GPU
 https://eax.me/opengl-vbo-vao-shaders/*/   
    glGenBuffers(1, &g_vertexBufferObject);                                                        GL_CHECK_ERRORS;
    glBindBuffer(GL_ARRAY_BUFFER, g_vertexBufferObject);                                           GL_CHECK_ERRORS;
    glBufferData(GL_ARRAY_BUFFER, 3 * 3 * sizeof(GLfloat), (GLfloat*)quadPos, GL_STATIC_DRAW);     GL_CHECK_ERRORS; // Л. загрузили в память GPU quadPos


/*Еще 2 строчек -  Vertex Arrays Object (VAO) — штука, которая говорит OpenGL, какую часть VBO следует использовать в последующих командах. 
 Представьте, что VAO представляет собой массив, в элементах которого хранится информация о том, какую часть некого VBO использовать, 
 и как эти данные нужно интерпретировать. Таким образом, один VAO по разным индексам может хранить координаты вершин, их цвета, нормали и прочие данные.
 Переключившись на нужный VAO мы можем эффективно обращаться к данным, на которые он «указывает», используя только индексы.
 https://eax.me/opengl-vbo-vao-shaders/*/   

    glGenVertexArrays(1, &g_vertexArrayObject);                                                    GL_CHECK_ERRORS;
    glBindVertexArray(g_vertexArrayObject);                                                        GL_CHECK_ERRORS;

    glBindBuffer(GL_ARRAY_BUFFER, g_vertexBufferObject);                                           GL_CHECK_ERRORS;
    glEnableVertexAttribArray(vertexLocation);                                                     GL_CHECK_ERRORS;
    glVertexAttribPointer(vertexLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);                            GL_CHECK_ERRORS;

    glBindVertexArray(0);
  }

	//цикл обработки сообщений и отрисовки сцены каждый кадр

  // Л. glfwWindowShouldClose возвращает значение флага закрытия указанного окна.
	while (!glfwWindowShouldClose(window))
	{

    /* Л. glfwPollEvents  обрабатывает только те события, которые уже находятся в очереди событий, а затем сразу же возвращается. 
    Обработка событий вызовет окно и входные обратные вызовы, связанные с этими событиями. */

		glfwPollEvents();

		//очищаем экран каждый кадр
//Л. glClearColor задает красные, зеленые, синие и Альфа-значения, используемые glClear для очистки цветовых буферов.
		glClearColor(0.1f, 0.1f, 0.1f, 1.0f);               GL_CHECK_ERRORS;

/*Л. glClear устанавливает область окна к ранее выбранным значениям по glClearColor, glClearIndex, glClearDepth, glClearStencil, и glClearAccum.
  Несколько цветовых буферов можно очистить одновременно, выбрав более чем один буфер за раз, используя glDrawBuffer.    */
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); GL_CHECK_ERRORS;
/* Л. program.StartUseShader() запускаем шейдеры*/
    program.StartUseShader();                           GL_CHECK_ERRORS;


    // очистка и заполнение экрана цветом
    //
    /* Л.  glViewport определяет аффинное преобразование координат x и y из нормализованных координат устройства в координаты окна.  
    https://www.khronos.org/registry/OpenGL-Refpages/es2.0/xhtml/glViewport.xml*/
    glViewport  (0, 0, WIDTH, HEIGHT);

    /*Л. следующие две строчки - см.ранее*/
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear     (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // draw call
    //

    /*Л. рисуем примитивы, начало - на  158 строке
      https://eax.me/opengl-vbo-vao-shaders/*/   

    glBindVertexArray(g_vertexArrayObject); GL_CHECK_ERRORS;
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  GL_CHECK_ERRORS;  // The last parameter of glDrawArrays is equal to VS invocations
    
    program.StopUseShader();
//Л. glfwSwapBuffers меняет местами передний и задний буферы указанного окна. Если интервал подкачки больше нуля, драйвер GPU ожидает указанное количество обновлений экрана перед заменой буферов.
		glfwSwapBuffers(window); 
	}

	//очищаем vbo и vao перед закрытием программы
  //
	glDeleteVertexArrays(1, &g_vertexArrayObject);
  glDeleteBuffers(1,      &g_vertexBufferObject);

	glfwTerminate();
	return 0;
}
