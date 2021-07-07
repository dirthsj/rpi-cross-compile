#pragma once
#include <string>

class HttpClient
{
    private:
        std::string host;
    public:
        HttpClient(std::string host);
        void get(std::string url);
};