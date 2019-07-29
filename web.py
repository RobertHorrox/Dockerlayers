from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate


class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = 'this-really-needs-to-be-changed'
    SQLALCHEMY_DATABASE_URI = "postgresql://postgres:docker@postgres/wordcount_dev"


app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)
migrate = Migrate(app, db)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))

    def __repr__(self):
        return '<User %r>' % self.name


@app.route('/')
def hello_world():
    u = User(name="hello world")
    db.session.add(u)
    db.session.commit()
    return User.query.all()[0].__repr__()

@app.route('/live')
def live():
    return ""
@app.route('/ready')
def ready():
    return ""
