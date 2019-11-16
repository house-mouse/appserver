#include <string>
#include <vector>
#include <memory>

// The great uniform resource locator
class URL {
    
};

// An object that can go in a log, of course!
class LogObject {
    
};

class LogObjectVariable {
public:
    const char *variable_name;
    
};

class NativeLogLine {
public:
    // These are being treated uniquely for optimization
    // reasons; they could be log objects but converting
    // them probably doesn't make sense
    const char *file;   // static from gcc/clang/etc
    const char *func;   // pretty function name
    uint32_t line;      // line number
    uint64_t datetime;  // date/time
    uint32_t log_level; // trace/debug/info/etc...
    
    std::vector<LogObject> objects;
};

class FilePath {
    std::shared_ptr<FilePath> parent; // parent if relative
    std::vector<std::string> unescaped_path_parts;
    
    const char *path_seperator; // "/" on unix

public:
    FilePath(const char *escaped_path);
    
    // These return properly escaped string representations
    virtual std::string as_string();
    virtual std::string basename();    
};
