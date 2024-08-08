package swagger

import (
	"net/http"

	// unnamed import of statik for swagger UI support
	_ "github.com/classic-terra/core/v3/client/docs/statik"
	"github.com/gorilla/mux"
	"github.com/rakyll/statik/fs"
)

var FS http.FileSystem

// RegisterSwaggerAPI registers swagger route with API Server
func RegisterSwaggerAPI(rtr *mux.Router) {
	staticServer := http.FileServer(FS)
	rtr.PathPrefix("/swagger/").Handler(http.StripPrefix("/swagger/", staticServer))
}

func init() {
	FS, _ = fs.New()
}
