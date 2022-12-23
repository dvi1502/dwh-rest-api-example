using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Http;
using System.Xml;
using System.Xml.Linq;
using terra.Common;

namespace terra.Controllers
{
    public class SipmentsByDocDateController : ApiController
    {
        private ErrorContainer errors = new ErrorContainer();

        private HttpResponseMessage GetResponse(XDocument doc)
        {
            XDocument xdoc = XDocument.Parse(doc.ToString());
            HttpResponseMessage response = this.Request.CreateResponse(HttpStatusCode.OK);
            response.Content = new StringContent(xdoc.ToString(), Encoding.UTF8, "application/xml");
            return response;
        }

        // GET: api/SipmentsByDocDate/?StartDate=2020-04-20T00:00:00&EndDate=2020-04-21T00:00:00
        public HttpResponseMessage Get(DateTime StartDate, DateTime EndDate)
        {

            errors.Clear();
            XDocument doc = new XDocument(new XElement("response"));

            using (SqlConnection conn = SqlHelper.GetConnection())
            {
                List<SqlParameter> sqlParameters = new List<SqlParameter>();
                sqlParameters.Add(new SqlParameter($"@StartDate", StartDate));
                sqlParameters.Add(new SqlParameter($"@EndDate", EndDate));
                using (SqlCommand cmd = SqlHelper.GetCommand("SELECT [IIS].[fnGetSipmentListByDocDate] (@StartDate, @EndDate)", conn, sqlParameters))
                {
                    try
                    {
                        using (XmlReader xmlReader = cmd.ExecuteXmlReader())
                        {

                            if (xmlReader.MoveToContent() != XmlNodeType.None)
                            {
                                XElement someElement = XElement.Load(xmlReader.ReadSubtree());
                                doc.Root.Add(someElement);
                            }
                            else
                            {
                                errors.Add("No objects.");
                            }

                        }

                        doc.Root.Add(errors.GetXElement());
                        return GetResponse(doc);

                    }
                    catch (Exception ex)
                    {
                        errors.Add(ex.Message);
                        doc.Root.Add(errors.GetXElement());
                        return GetResponse(doc);
                    }

                }

            }

        }

    }
}
