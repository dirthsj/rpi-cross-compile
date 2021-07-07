#include <iostream>
#include "http_client.hpp"

int main() {
    HttpClient client("example.com");
    client.get("/");
    std::cout << "Hello World" << std::endl;
    return 0;
}