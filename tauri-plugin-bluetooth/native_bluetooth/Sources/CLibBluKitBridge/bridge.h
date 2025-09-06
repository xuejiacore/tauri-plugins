#ifdef __cplusplus
extern "C" {
#endif

// echo for test
const char* echo(const char* echo);

// initialize the bluetooth, include delegate
void initialize();

// start scan
bool start_scanning();

// stop scan
bool stop_scanning();

// set passive mode
void set_passive_mode(bool);

// connect to device
bool connect_device(const char* identifier);

// disconnect device
bool disconnect_device(const char* identifier);

// read rssi
int readRssi(const char* identifier);

void set_delegate();

#ifdef __cplusplus
}
#endif
